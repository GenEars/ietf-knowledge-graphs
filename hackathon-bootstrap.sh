#!/usr/bin/env bash
# ============================================================================
# Hackathon Bootstrap - RDF4J + SPARQLWorks
# - Creates (or recreates) an RDF4J repository
# - Loads schema + instance TTLs
# - Adds global Tomcat CORS filter
# - Skips Tomcat restart by default (Windows Git Bash safe)
#
# Files expected in same directory:
#   ./simap-rdfs-schema.ttl
#   ./pwe3-dynamic-topology.ttl
#
# Environment overrides (optional):
#   REPO_ID=ietf-core-test         # default: ietf-core
#   TOMCAT_HOME=/opt/tomcat        # e.g. /d/Apps/apache-tomcat-9.0.106 on Git Bash
#   RDF4J_BASE=http://localhost:8080/rdf4j-server
#   WORKBENCH_URL=http://localhost:8080/rdf4j-workbench
#   SKIP_TOMCAT_RESTART=1          # default: 1 (safe on Windows Git Bash)
#
# Convenience flags:
#   ./hackathon-bootstrap.sh --test    # sets REPO_ID=ietf-core-test and SKIP_TOMCAT_RESTART=1
#   ./hackathon-bootstrap.sh --restart # forces Tomcat restart via startup.sh/shutdown.sh
# ============================================================================

set -euo pipefail

### ---- Flags ----------------------------------------------------------------
if [[ "${1-}" == "--test" ]]; then
  export REPO_ID="${REPO_ID:-ietf-core-test}"
  export SKIP_TOMCAT_RESTART=1
elif [[ "${1-}" == "--restart" ]]; then
  export SKIP_TOMCAT_RESTART=0
fi

### ---- Config ---------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_ID="${REPO_ID:-ietf-core}"
RDF4J_BASE="${RDF4J_BASE:-http://localhost:8080/rdf4j-server}"
WORKBENCH_URL="${WORKBENCH_URL:-http://localhost:8080/rdf4j-workbench}"
REPO_URL="$RDF4J_BASE/repositories/$REPO_ID"
STATEMENTS_URL="$REPO_URL/statements"

# Tomcat - only needed for CORS edit / restart (skip by default on Windows)
TOMCAT_HOME="${TOMCAT_HOME:-/opt/tomcat}"
WEBXML="$TOMCAT_HOME/conf/web.xml"
SKIP_TOMCAT_RESTART="${SKIP_TOMCAT_RESTART:-1}"

# Files: expected alongside the script
SCHEMA_FILE="$SCRIPT_DIR/simap-rdfs-schema.ttl"
INSTANCE_FILE="$SCRIPT_DIR/pwe3-dynamic-topology.ttl"

CTX_SCHEMA="http://www.huawei.com/graph/schema"
CTX_INSTANCE="http://www.huawei.com/graph/instance/pwe3-dynamic-topology"

### ---- Curl wrapper: always bypass proxy for localhost ----------------------
# Prevent CNTLM/other proxies interfering with local server calls
export no_proxy=localhost,127.0.0.1
export NO_PROXY=localhost,127.0.0.1
CURL="curl --noproxy localhost"

die() { echo "ERROR: $*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"; }

### ---- Sanity checks --------------------------------------------------------
need curl
[[ -f "$SCHEMA_FILE" ]]   || die "Schema file not found: $SCHEMA_FILE"
[[ -f "$INSTANCE_FILE" ]] || die "Instance file not found: $INSTANCE_FILE"

echo "[Info] Repository ID            : $REPO_ID"
echo "[Info] RDF4J Server             : $RDF4J_BASE"
echo "[Info] Workbench                : $WORKBENCH_URL"
echo "[Info] Schema TTL               : $SCHEMA_FILE"
echo "[Info] Instance TTL             : $INSTANCE_FILE"
echo "[Info] Tomcat (for CORS edit)   : $TOMCAT_HOME"
echo "[Info] Skip Tomcat restart      : $SKIP_TOMCAT_RESTART"
echo

### ---- Add Tomcat CORS (idempotent) ----------------------------------------
if [[ -f "$WEBXML" ]]; then
  if ! grep -q 'org.apache.catalina.filters.CorsFilter' "$WEBXML"; then
    echo "[CORS] Adding CorsFilter to $WEBXML (backup at web.xml.bak)"
    cp "$WEBXML" "$WEBXML.bak"

    awk '
      /<\/web-app>/ && !done {
        print "    <!-- === Global CORS for all webapps (including RDF4J Server) === -->"
        print "    <filter>"
        print "      <filter-name>CorsFilter</filter-name>"
        print "      <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>"
        print "      <init-param><param-name>cors.allowed.origins</param-name><param-value>*</param-value></init-param>"
        print "      <init-param><param-name>cors.allowed.methods</param-name><param-value>GET,POST,HEAD,OPTIONS</param-value></init-param>"
        print "      <init-param><param-name>cors.allowed.headers</param-name><param-value>Content-Type,Accept,Origin,Authorization,Access-Control-Request-Method,Access-Control-Request-Headers</param-value></init-param>"
        print "    </filter>"
        print "    <filter-mapping><filter-name>CorsFilter</filter-name><url-pattern>/*</url-pattern></filter-mapping>"
        done=1
      }
      { print }
    ' "$WEBXML" > "$WEBXML.tmp" && mv "$WEBXML.tmp" "$WEBXML"
  else
    echo "[CORS] CorsFilter already present - skipping"
  fi
else
  echo "[CORS] Skipping (no Tomcat web.xml found at $WEBXML)"
fi

### ---- Tomcat restart (safe default: skip for Windows/Git Bash) ------------
if [[ "$SKIP_TOMCAT_RESTART" == "1" ]]; then
  echo "[Tomcat] Skipping restart (safe mode)."
  echo "         If needed on Windows, restart manually via CMD:"
  echo "         cd /d %TOMCAT_HOME%\\bin && shutdown.bat && startup.bat"
else
  echo "[Tomcat] Restarting..."
  if [[ -x "$TOMCAT_HOME/bin/shutdown.sh" ]]; then "$TOMCAT_HOME/bin/shutdown.sh" || true; sleep 2; fi
  if [[ -x "$TOMCAT_HOME/bin/startup.sh"  ]]; then "$TOMCAT_HOME/bin/startup.sh"; else die "startup.sh not found in $TOMCAT_HOME/bin"; fi
fi

### ---- Wait for RDF4J server -----------------------------------------------
echo -n "[RDF4J] Waiting for server at $RDF4J_BASE"
for i in {1..60}; do
  if $CURL -fsS "$RDF4J_BASE" >/dev/null 2>&1; then echo " - up"; break; fi
  echo -n "."
  sleep 1
  [[ "$i" -eq 60 ]] && die "RDF4J Server did not respond in time."
done

### ---- Delete existing repo (if any) ---------------------------------------
echo "[RDF4J] Deleting repository $REPO_ID (if exists)"
$CURL -fsS -X DELETE "$RDF4J_BASE/repositories/$REPO_ID" >/dev/null 2>&1 || true

### ---- Create repository (verbose to show errors) --------------------------
echo "[RDF4J] Creating repository $REPO_ID"

read -r -d '' REPO_CFG <<TTL
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rep:  <http://www.openrdf.org/config/repository#> .
@prefix sr:   <http://www.openrdf.org/config/repository/sail#> .
@prefix sail: <http://www.openrdf.org/config/sail#> .
@prefix ns:   <http://www.openrdf.org/config/sail/native#> .

[] a rep:Repository ;
   rep:repositoryID "${REPO_ID}" ;
   rdfs:label "${REPO_ID}" ;
   rep:repositoryImpl [
     rep:repositoryType "openrdf:SailRepository" ;
     sr:sailImpl [
       sail:sailType "openrdf:NativeStore" ;
       ns:tripleIndexes "spoc,posc,opsc"
     ]
   ] .
TTL

# Verbose, no proxy for localhost
$CURL -v -X POST "$RDF4J_BASE/repositories" \
  -H "Accept: application/sparql-results+xml" \
  -F "config=@-;type=application/x-turtle" <<<"$REPO_CFG"

# Confirm creation
echo "[RDF4J] Current repositories:"
$CURL -s "$RDF4J_BASE/repositories" | sed -n 's:.*<id>\(.*\)</id>.*:\1:p' || true
echo

### ---- Load data -----------------------------------------------------------
echo "[RDF4J] Loading schema: $SCHEMA_FILE"
$CURL -v -X POST "$STATEMENTS_URL?context=<${CTX_SCHEMA}>" \
  -H "Content-Type: text/turtle" \
  --data-binary @"$SCHEMA_FILE"

echo "[RDF4J] Loading instance: $INSTANCE_FILE"
$CURL -v -X POST "$STATEMENTS_URL?context=<${CTX_INSTANCE}>" \
  -H "Content-Type: text/turtle" \
  --data-binary @"$INSTANCE_FILE"

### ---- Final info ----------------------------------------------------------
echo
echo "Ready!"
echo "Workbench (open this):"
echo "  $WORKBENCH_URL/repositories/$REPO_ID/summary"
echo
echo "SPARQL endpoint for SPARQLWorks:"
echo "  $REPO_URL"
echo
