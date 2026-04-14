param(
  [Parameter(Mandatory = $true)]
  [string]$SourcePath,
  [string]$OutRoot = "archives/chatgpt_exports"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$sourceAbs = (Resolve-Path -LiteralPath $SourcePath).Path
$outRootAbs = Join-Path $RepoRoot $OutRoot

function Convert-FromUnixTime {
  param([object]$Value)

  if ($null -eq $Value) { return $null }

  $raw = ($Value | Out-String).Trim()
  if ([string]::IsNullOrWhiteSpace($raw)) { return $null }

  try {
    $seconds = [int64][double]$raw
    return [DateTimeOffset]::FromUnixTimeSeconds($seconds).UtcDateTime.ToString("o")
  }
  catch {
    return $null
  }
}

function Get-SafeText {
  param([object]$Value)

  if ($null -eq $Value) { return "" }
  return ($Value | Out-String).Trim()
}

function Get-Slug {
  param(
    [string]$Title,
    [string]$Fallback
  )

  $candidate = if ($Title) { $Title } else { $Fallback }
  $candidate = $candidate.ToLowerInvariant()
  $candidate = [regex]::Replace($candidate, "[^a-z0-9]+", "-").Trim("-")
  if ([string]::IsNullOrWhiteSpace($candidate)) {
    return "conversation"
  }
  return $candidate
}

function Get-MessageText {
  param($Message)

  if ($null -eq $Message) { return "" }
  if ($null -eq $Message.content) { return "" }

  $parts = @()
  if ($Message.content.PSObject.Properties.Name -contains "parts") {
    foreach ($part in @($Message.content.parts)) {
      $text = Get-SafeText $part
      if ($text) { $parts += $text }
    }
  }

  if ($parts.Count -gt 0) {
    return ($parts -join "`r`n`r`n").Trim()
  }

  $textValue = Get-SafeText $Message.content.text
  if ($textValue) { return $textValue }

  return ""
}

function Get-ConversationMessages {
  param($Conversation)

  $messages = @()
  if ($null -eq $Conversation.mapping) { return $messages }

  foreach ($entry in $Conversation.mapping.PSObject.Properties) {
    $node = $entry.Value
    if ($null -eq $node -or $null -eq $node.message) { continue }

    $role = Get-SafeText $node.message.author.role
    $text = Get-MessageText $node.message
    $createdIso = Convert-FromUnixTime $node.message.create_time
    $createdSort = if ($createdIso) { $createdIso } else { "9999-12-31T23:59:59Z" }

    if (-not $role -and -not $text) { continue }

    $messages += [pscustomobject]@{
      Role       = if ($role) { $role } else { "unknown" }
      Text       = $text
      CreatedIso = $createdIso
      CreatedSort = $createdSort
    }
  }

  return @($messages | Sort-Object CreatedSort, Role)
}

function Write-ConversationMarkdown {
  param(
    [string]$OutPath,
    [string]$Title,
    [string]$ConversationId,
    [string]$CreatedAt,
    [string]$UpdatedAt,
    [object[]]$Messages
  )

  $lines = New-Object System.Collections.Generic.List[string]
  $safeTitle = if ($Title) { $Title } else { "Untitled Conversation" }
  $lines.Add("# $safeTitle")
  $lines.Add("")
  $lines.Add("- Conversation ID: ``$ConversationId``")
  if ($CreatedAt) { $lines.Add("- Created: $CreatedAt") }
  if ($UpdatedAt) { $lines.Add("- Updated: $UpdatedAt") }
  $lines.Add("- Messages: $($Messages.Count)")
  $lines.Add("")

  foreach ($message in $Messages) {
    $heading = "## $($message.Role)"
    if ($message.CreatedIso) {
      $heading = "$heading - $($message.CreatedIso)"
    }

    $lines.Add($heading)
    $lines.Add("")

    $body = if ($message.Text) { $message.Text } else { "_No text content captured._" }
    foreach ($bodyLine in ($body -split "`r?`n")) {
      $lines.Add($bodyLine)
    }

    $lines.Add("")
  }

  $content = ($lines -join "`r`n").TrimEnd() + "`r`n"
  Set-Content -LiteralPath $OutPath -Value $content -Encoding UTF8
}

$cleanupDir = $null
$jsonAbs = $null
$chatHtmlAbs = $null

try {
  switch ([System.IO.Path]::GetExtension($sourceAbs).ToLowerInvariant()) {
    ".zip" {
      $cleanupDir = Join-Path ([System.IO.Path]::GetTempPath()) ("gm-chatgpt-export-" + [guid]::NewGuid().ToString("N"))
      New-Item -ItemType Directory -Path $cleanupDir -Force | Out-Null
      Expand-Archive -LiteralPath $sourceAbs -DestinationPath $cleanupDir -Force

      $jsonItem = Get-ChildItem -Path $cleanupDir -Recurse -Filter "conversations.json" | Select-Object -First 1
      if ($null -eq $jsonItem) {
        throw "Could not find conversations.json in export zip."
      }

      $jsonAbs = $jsonItem.FullName
      $chatItem = Get-ChildItem -Path $cleanupDir -Recurse -Filter "chat.html" | Select-Object -First 1
      if ($chatItem) { $chatHtmlAbs = $chatItem.FullName }
    }
    ".json" {
      $jsonAbs = $sourceAbs
    }
    default {
      throw "Unsupported source type. Use a ChatGPT export .zip or a conversations.json file."
    }
  }

  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $runDir = Join-Path $outRootAbs $timestamp
  $rawDir = Join-Path $runDir "raw"
  $conversationDir = Join-Path $runDir "conversations"

  New-Item -ItemType Directory -Path $rawDir -Force | Out-Null
  New-Item -ItemType Directory -Path $conversationDir -Force | Out-Null

  Copy-Item -LiteralPath $jsonAbs -Destination (Join-Path $rawDir "conversations.json") -Force
  if ($chatHtmlAbs) {
    Copy-Item -LiteralPath $chatHtmlAbs -Destination (Join-Path $rawDir "chat.html") -Force
  }

  $conversations = Get-Content -LiteralPath $jsonAbs -Raw | ConvertFrom-Json -Depth 100
  $conversationList = @($conversations)
  $manifestItems = @()
  $indexLines = New-Object System.Collections.Generic.List[string]

  $indexLines.Add("# ChatGPT Export Import")
  $indexLines.Add("")
  $indexLines.Add("- Imported: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")")
  $indexLines.Add("- Source: ``$sourceAbs``")
  $indexLines.Add("- Conversations: $($conversationList.Count)")
  $indexLines.Add("")
  $indexLines.Add("## Conversations")
  $indexLines.Add("")

  $usedSlugs = @{}

  foreach ($conversation in ($conversationList | Sort-Object { Convert-FromUnixTime $_.update_time }, { Get-SafeText $_.title })) {
    $title = Get-SafeText $conversation.title
    if (-not $title) { $title = "Untitled Conversation" }

    $conversationId = Get-SafeText $conversation.conversation_id
    if (-not $conversationId) { $conversationId = Get-SafeText $conversation.id }
    if (-not $conversationId) { $conversationId = [guid]::NewGuid().ToString("N") }

    $createdAt = Convert-FromUnixTime $conversation.create_time
    $updatedAt = Convert-FromUnixTime $conversation.update_time
    $messages = Get-ConversationMessages $conversation

    $baseSlug = Get-Slug -Title $title -Fallback $conversationId.Substring(0, [Math]::Min(8, $conversationId.Length))
    $slug = $baseSlug
    $counter = 2
    while ($usedSlugs.ContainsKey($slug)) {
      $slug = "$baseSlug-$counter"
      $counter++
    }
    $usedSlugs[$slug] = $true

    $fileName = "$slug.md"
    $relativePath = "conversations/$fileName"
    $outPath = Join-Path $conversationDir $fileName
    Write-ConversationMarkdown -OutPath $outPath -Title $title -ConversationId $conversationId -CreatedAt $createdAt -UpdatedAt $updatedAt -Messages $messages

    $userCount = @($messages | Where-Object { $_.Role -eq "user" }).Count
    $assistantCount = @($messages | Where-Object { $_.Role -eq "assistant" }).Count

    $manifestItems += [pscustomobject]@{
      title = $title
      conversation_id = $conversationId
      created_at = $createdAt
      updated_at = $updatedAt
      message_count = $messages.Count
      user_messages = $userCount
      assistant_messages = $assistantCount
      path = $relativePath
    }

    $stamp = if ($updatedAt) { $updatedAt } elseif ($createdAt) { $createdAt } else { "unknown time" }
    $indexLines.Add("- [$title]($relativePath) - $($messages.Count) messages - updated $stamp")
  }

  $indexContent = ($indexLines -join "`r`n").TrimEnd() + "`r`n"
  Set-Content -LiteralPath (Join-Path $runDir "index.md") -Value $indexContent -Encoding UTF8

  $manifest = [pscustomobject]@{
    imported_at = (Get-Date).ToUniversalTime().ToString("o")
    source = $sourceAbs
    conversation_count = $conversationList.Count
    conversations = @($manifestItems)
  }

  $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runDir "manifest.json") -Encoding UTF8

  Write-Host "ChatGPT export imported -> $runDir"
  Write-Host "Index -> $(Join-Path $runDir 'index.md')"
}
finally {
  if ($cleanupDir -and (Test-Path $cleanupDir)) {
    Remove-Item -LiteralPath $cleanupDir -Recurse -Force
  }
}
