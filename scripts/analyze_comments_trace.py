#!/usr/bin/env python3
"""
Analyze useAllCommentsDataQuery timing from cc-graphql Splunk logs for a given trace ID.

Usage:
    python3 scripts/analyze_comments_trace.py <trace_id> [--earliest <time>] [--latest <time>]

Examples:
    python3 scripts/analyze_comments_trace.py b1322320672e42c29ce2498ee461fc1b
    python3 scripts/analyze_comments_trace.py b1322320672e42c29ce2498ee461fc1b --earliest -48h
    python3 scripts/analyze_comments_trace.py d1b5bc2060cb46f0a15bfc75229179d7 --earliest 2026-03-26T10:00:00Z --latest 2026-03-26T11:00:00Z

Requires: atlas CLI with slauth configured for splunk.paas-inf.net
    Run first: atlas slauth token -a splunk.paas-inf.net -g atlassian-all --mfa
"""

import argparse
import json
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from typing import Optional, List, Dict


CC_GRAPHQL_INDEX = "fced3ce6-dce5-4048-af4c-2b656fa57032"

SPLUNK_SCRIPT = None  # Will use direct atlas slauth curl


def run_splunk_query(query: str, earliest: str, latest: str, max_results: int = 200) -> List[Dict]:
    """Run a Splunk search via the splunk_search.py helper script if available, otherwise fail gracefully."""
    # Try using the skill's splunk_search.py script
    script_path = "/Users/jtaylor11/.agents/skills/confluence-investigate-issue/scripts/splunk_search.py"
    cmd = [
        sys.executable, script_path,
        "search",
        query,
        f"--earliest-time={earliest}",
        f"--latest-time={latest}",
        f"--max-results={max_results}",
        "--json",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if result.returncode == 0 and result.stdout.strip():
        data = json.loads(result.stdout)
        if isinstance(data, dict) and "results" in data:
            return data["results"]
        elif isinstance(data, list):
            return data
        return []

    # If we get here, the query failed
    print(f"Splunk query failed (rc={result.returncode})", file=sys.stderr)
    if result.stderr:
        print(f"stderr: {result.stderr[:500]}", file=sys.stderr)
    if result.stdout:
        print(f"stdout: {result.stdout[:500]}", file=sys.stderr)

    # Fallback: construct the REST API call directly
    import urllib.parse
    search_query = urllib.parse.quote(query)
    print(f"ERROR: Could not run Splunk query. Ensure you have a valid slauth token.", file=sys.stderr)
    print(f"Run: atlas slauth token -a splunk.paas-inf.net -g atlassian-all --mfa", file=sys.stderr)
    sys.exit(1)


def query_trace(trace_id: str, earliest: str, latest: str) -> List[Dict]:
    """Query all useAllCommentsDataQuery log lines for a trace ID from cc-graphql."""
    query = (
        f'search index={CC_GRAPHQL_INDEX} "{trace_id}" opId="useAllCommentsDataQuery"'
        f' | spath'
        f' | sort _time'
        f' | table _time time logger_name message elapsed duration opId operation_id orgTime'
        f' spanId shardId tenantId accountId status'
        f' req_completed req_first_bytes req_first_bytes_time'
        f' res_completed res_first_bytes res_first_bytes_time res_received res_total_bytes'
    )
    return run_splunk_query(query, earliest, latest, max_results=200)


def parse_timestamp(time_str: str) -> Optional[datetime]:
    """Parse various timestamp formats from Splunk logs."""
    if not time_str:
        return None
    # Try ISO format: 2026-03-24T23:33:32.687844938Z
    for fmt in [
        "%Y-%m-%dT%H:%M:%S.%fZ",
        "%Y-%m-%dT%H:%M:%S.%f+00:00",
        "%Y-%m-%dT%H:%M:%S+00:00",
    ]:
        try:
            # Truncate nanoseconds to microseconds for Python
            cleaned = time_str
            if "." in cleaned and "Z" in cleaned:
                parts = cleaned.split(".")
                frac = parts[1].rstrip("Z")
                if len(frac) > 6:
                    frac = frac[:6]
                cleaned = f"{parts[0]}.{frac}Z"
            return datetime.strptime(cleaned, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def parse_org_time(org_time: str, reference_date: datetime) -> Optional[datetime]:
    """Parse orgTime (e.g. '23:33:32.744') using a reference date for the date portion."""
    if not org_time:
        return None
    try:
        t = datetime.strptime(org_time, "%H:%M:%S.%f").time()
        return datetime.combine(reference_date.date(), t, tzinfo=timezone.utc)
    except ValueError:
        return None


def unwrap(val):
    """Unwrap list values from Splunk (sometimes fields come as arrays)."""
    if isinstance(val, list):
        return val[0] if val else None
    return val


def analyze_trace(results, trace_id, client_durations=None):
    """Analyze and display timing breakdown for each useAllCommentsDataQuery execution.

    Args:
        results: List of Splunk result dicts
        trace_id: The trace ID being analyzed
        client_durations: Optional dict mapping request number (1-based) to client duration in seconds,
                          or a single float applied to request 1
    """

    # Normalize client_durations
    if isinstance(client_durations, (int, float)):
        client_durations = {1: float(client_durations)}
    elif client_durations is None:
        client_durations = {}

    # Group by spanId
    spans = defaultdict(list)
    for r in results:
        span_id = unwrap(r.get("spanId", ""))
        if span_id:
            spans[span_id].append(r)

    if not spans:
        print(f"\nNo useAllCommentsDataQuery results found for trace {trace_id}")
        return

    print(f"\n{'='*90}")
    print(f"  Trace: {trace_id}")
    print(f"  Found {len(spans)} useAllCommentsDataQuery request(s)")
    print(f"{'='*90}")

    for i, (span_id, logs) in enumerate(sorted(spans.items(), key=lambda x: x[1][0].get("_time", "")), 1):

        # Extract metadata from first log
        first_log = logs[0]
        shard = unwrap(first_log.get("shardId", "unknown"))
        tenant = unwrap(first_log.get("tenantId", "unknown"))

        # Find the "Call completed" log (GraphQlService)
        call_completed = None
        backend_calls = []
        request_stats = []

        for log in logs:
            logger = unwrap(log.get("logger_name", ""))
            if logger == "GraphQlService":
                call_completed = log
            elif logger == "ContextualMicrosHttpAsyncClient":
                request_stats.append(log)
            elif logger == "LoggingHttpAsyncResponseInterceptor":
                duration = unwrap(log.get("duration", ""))
                if duration:
                    backend_calls.append(log)

        # Server-side total elapsed
        server_elapsed_ms = None
        server_complete_time = None
        server_start_time = None
        if call_completed:
            server_elapsed_ms = int(unwrap(call_completed.get("elapsed", 0)))
            time_str = unwrap(call_completed.get("time", ""))
            server_complete_time = parse_timestamp(time_str)
            if server_complete_time:
                server_start_time = datetime.fromtimestamp(
                    server_complete_time.timestamp() - server_elapsed_ms / 1000.0,
                    tz=timezone.utc,
                )

        # Client duration for this request
        client_ms = None
        if i in client_durations:
            client_ms = client_durations[i] * 1000

        # ── Header ──
        print(f"\n{'─'*90}")
        print(f"  Request {i}")
        print(f"{'─'*90}")

        # ── Client Experience (prominent) ──
        if client_ms is not None and server_elapsed_ms is not None:
            gap_ms = client_ms - server_elapsed_ms
            print(f"  ┌─────────────────────────────────────────────────────┐")
            print(f"  │  Client duration:    {client_ms:>8.0f}ms  ({client_ms/1000:.2f}s)          │")
            print(f"  │  Server processing:  {server_elapsed_ms:>8}ms  ({server_elapsed_ms/1000:.2f}s)          │")
            print(f"  │  Edge/network gap:   {gap_ms:>8.0f}ms  ({gap_ms/1000:.2f}s)  {gap_ms/client_ms*100:>5.1f}%    │")
            print(f"  └─────────────────────────────────────────────────────┘")
        elif server_elapsed_ms is not None:
            print(f"  ┌─────────────────────────────────────────────────────┐")
            print(f"  │  Server processing:  {server_elapsed_ms:>8}ms  ({server_elapsed_ms/1000:.2f}s)          │")
            print(f"  │  Client duration:    (use --client-duration)       │")
            print(f"  └─────────────────────────────────────────────────────┘")

        # ── Metadata ──
        if server_start_time and server_complete_time:
            print(f"  Server window:  {server_start_time.strftime('%H:%M:%S.%f')[:-3]} → {server_complete_time.strftime('%H:%M:%S.%f')[:-3]} UTC")
        print(f"  Shard:          {shard}")
        print(f"  SpanId:         {span_id}")

        # ── Backend calls breakdown ──
        if backend_calls or request_stats:
            # Build call entries by merging data from both log types.
            call_entries = []

            rs_sorted = sorted(request_stats, key=lambda x: unwrap(x.get("orgTime", "")))
            for rs in rs_sorted:
                org_time = unwrap(rs.get("orgTime", ""))
                res_completed = unwrap(rs.get("res_completed", ""))
                res_total_bytes = unwrap(rs.get("res_total_bytes", ""))
                call_entries.append({
                    "org_time": org_time,
                    "duration_ms": int(res_completed) if res_completed else None,
                    "total_bytes": int(res_total_bytes) if res_total_bytes else None,
                    "operation": "",
                })

            # Match operation_id from LoggingHttpAsyncResponseInterceptor by duration
            if backend_calls:
                bc_sorted = sorted(backend_calls, key=lambda x: unwrap(x.get("_time", "")))
                bc_ops = []
                for bc in bc_sorted:
                    op_id = unwrap(bc.get("operation_id", ""))
                    duration = unwrap(bc.get("duration", ""))
                    bc_ops.append((int(duration) if duration else None, op_id))

                used_bc = set()
                for entry in call_entries:
                    best_match = None
                    best_diff = float("inf")
                    for k, (bc_dur, bc_op) in enumerate(bc_ops):
                        if k in used_bc or bc_dur is None or entry["duration_ms"] is None:
                            continue
                        diff = abs(bc_dur - entry["duration_ms"])
                        if diff < best_diff:
                            best_diff = diff
                            best_match = k
                    if best_match is not None and best_diff <= 5:
                        used_bc.add(best_match)
                        entry["operation"] = bc_ops[best_match][1]

                for k, (bc_dur, bc_op) in enumerate(bc_ops):
                    if k not in used_bc:
                        call_entries.append({
                            "org_time": unwrap(bc_sorted[k].get("_time", "")),
                            "duration_ms": bc_dur,
                            "total_bytes": None,
                            "operation": bc_op,
                        })

            call_entries.sort(key=lambda x: x.get("org_time", ""))

            print(f"\n  Backend calls to monolith:")
            print(f"  {'#':<4} {'Completed (UTC)':<18} {'Duration':>10} {'Resp Size':>11}  {'Operation'}")
            print(f"  {'─'*4} {'─'*18} {'─'*10} {'─'*11}  {'─'*35}")

            for j, entry in enumerate(call_entries, 1):
                ot = entry["org_time"] or "?"
                dur = entry["duration_ms"]
                dur_str = f"{dur}ms" if dur is not None else "?"
                bytes_str = f"{entry['total_bytes']:,}B" if entry.get("total_bytes") else "?"
                op = entry.get("operation", "") or "?"
                print(f"  {j:<4} {ot:<18} {dur_str:>10} {bytes_str:>11}  {op}")

    print()


def main():
    parser = argparse.ArgumentParser(
        description="Analyze useAllCommentsDataQuery timing from cc-graphql Splunk logs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("trace_id", help="The x-b3-traceid / traceId to analyze")
    parser.add_argument("--earliest", default="-48h", help="Earliest time for Splunk search (default: -48h)")
    parser.add_argument("--latest", default="now", help="Latest time for Splunk search (default: now)")
    parser.add_argument("--client-duration", type=float, nargs="+", default=None, metavar="SECS",
                        help="Client-observed duration(s) in seconds (from network tab). "
                             "Provide one value per request in order. "
                             "E.g.: --client-duration 7.34 5.67")

    args = parser.parse_args()

    print(f"Querying cc-graphql logs for trace {args.trace_id}...")
    results = query_trace(args.trace_id, args.earliest, args.latest)

    if not results:
        print(f"\nNo results found for trace {args.trace_id}")
        print("Check that:")
        print("  1. Your slauth token is valid: atlas slauth token -a splunk.paas-inf.net -g atlassian-all --mfa")
        print("  2. The trace ID is correct")
        print(f"  3. The time range ({args.earliest} to {args.latest}) covers the request")
        sys.exit(1)

    # Build client_durations dict: {request_number: seconds}
    client_durations = {}
    if args.client_duration:
        for idx, dur in enumerate(args.client_duration, 1):
            client_durations[idx] = dur

    analyze_trace(results, args.trace_id, client_durations)


if __name__ == "__main__":
    main()
