#!/usr/bin/env python
import sys, json, argparse, requests

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["decide", "attest"])
    ap.add_argument("--infile", required=True)
    ap.add_argument("--url", default="http://127.0.0.1:5059")
    args = ap.parse_args()

    with open(args.infile, "r", encoding="utf-8") as f:
        payload = json.load(f)

    if args.cmd == "decide":
        r = requests.post(args.url + "/decide", json=payload, timeout=10)
        print(json.dumps(r.json(), ensure_ascii=False, indent=2))
    else:
        r = requests.post(args.url + "/attest", json=payload, timeout=10)
        print(json.dumps(r.json(), ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
