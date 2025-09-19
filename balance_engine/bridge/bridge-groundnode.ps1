param(
  [string]$ApiBase = "http://127.0.0.1:5059"
)

function Invoke-BalanceDecide {
  param([object]$Event)
  $json = $Event | ConvertTo-Json -Depth 16
  return Invoke-RestMethod -Uri "$ApiBase/decide" -Method POST -Body $json -ContentType "application/json"
}

function Invoke-BalanceAttest {
  param([object]$Event, [object]$Decision, [string]$Layer = "individual")
  $payload = @{ event = $Event; decision = $Decision; layer = $Layer } | ConvertTo-Json -Depth 16
  return Invoke-RestMethod -Uri "$ApiBase/attest" -Method POST -Body $payload -ContentType "application/json"
}

function Send-BalanceEvent {
  param(
    [Parameter(Mandatory)][ValidateSet("lie","steal","kill","destroy","truth","stewardship","care","creation")]
    [string]$Type,
    [string]$ActorId = "$env:USERNAME",
    [string]$Layer = "system",
    [hashtable]$Context = @{ note = "PS transcript event" },
    [string[]]$Evidence = @()
  )

  if ($Context.ContainsKey('line')) {
    $s = [string]$Context['line']
    $s = ($s -replace '\p{C}', ' ')
    if ($s.Length -gt 500) { $s = $s.Substring(0,500) + '…' }
    $Context['line'] = $s
  }

  $evtId = "evt-" + [Guid]::NewGuid().ToString("N")
  $event = @{
    id         = $evtId
    actor_id   = $ActorId
    type       = $Type
    context    = $Context
    evidence   = $Evidence
    timestamp  = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    layer_hint = $Layer
  }

  $decision = Invoke-BalanceDecide -Event $event
  $att = Invoke-BalanceAttest -Event $event -Decision $decision -Layer $Layer

  [pscustomobject]@{
    event_id = $evtId
    opposite = $decision.opposite
    plan     = ($decision.plan -join "; ")
    safety   = ($decision.safety_checks -join "; ")
    ledger   = $att.ledger
    hash     = $att.hash
  }
}
