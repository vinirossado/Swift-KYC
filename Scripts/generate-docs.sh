#!/usr/bin/env bash
#
# generate-docs.sh
#
# Builds the DocC documentation archive for IdentityKitCore and exports
# it as a static HTML site into the docs/ directory at the repository root.
#
# Usage:
#   ./Scripts/generate-docs.sh
#
# Requirements:
#   - Xcode 15+ (ships with docc and swift-docc-plugin support)
#   - Swift 5.10+

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/.build/docc"
OUTPUT_DIR="${REPO_ROOT}/docs"
MODULE_NAME="IdentityKitCore"

echo "==> Repository root: ${REPO_ROOT}"
echo "==> Module:          ${MODULE_NAME}"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Build the Swift package and generate the symbol graph
# ---------------------------------------------------------------------------
echo "==> Building package and generating symbol graph..."

SYMBOL_GRAPH_DIR="${BUILD_DIR}/symbol-graphs"
mkdir -p "${SYMBOL_GRAPH_DIR}"

swift build \
    --package-path "${REPO_ROOT}" \
    --target "${MODULE_NAME}" \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc "${SYMBOL_GRAPH_DIR}"

echo "    Symbol graphs written to ${SYMBOL_GRAPH_DIR}"
echo ""

# ---------------------------------------------------------------------------
# Step 2: Locate the .docc catalog
# ---------------------------------------------------------------------------
DOCC_CATALOG="${REPO_ROOT}/Sources/${MODULE_NAME}/Documentation.docc"

if [ ! -d "${DOCC_CATALOG}" ]; then
    echo "ERROR: DocC catalog not found at ${DOCC_CATALOG}" >&2
    exit 1
fi

echo "==> DocC catalog:    ${DOCC_CATALOG}"
echo ""

# ---------------------------------------------------------------------------
# Step 3: Build the .doccarchive
# ---------------------------------------------------------------------------
DOCC_ARCHIVE="${BUILD_DIR}/${MODULE_NAME}.doccarchive"

echo "==> Building .doccarchive..."

xcrun docc convert "${DOCC_CATALOG}" \
    --fallback-display-name "${MODULE_NAME}" \
    --fallback-bundle-identifier "io.identitykit.${MODULE_NAME}" \
    --fallback-bundle-version "1.0.0" \
    --additional-symbol-graph-dir "${SYMBOL_GRAPH_DIR}" \
    --output-path "${DOCC_ARCHIVE}"

echo "    Archive written to ${DOCC_ARCHIVE}"
echo ""

# ---------------------------------------------------------------------------
# Step 4: Export to static HTML
# ---------------------------------------------------------------------------
echo "==> Exporting to static HTML..."

rm -rf "${OUTPUT_DIR}"

xcrun docc process-archive transform-for-static-hosting "${DOCC_ARCHIVE}" \
    --hosting-base-path "identity-kit" \
    --output-path "${OUTPUT_DIR}"

echo "    Static site written to ${OUTPUT_DIR}"
echo ""

# ---------------------------------------------------------------------------
# Step 5: Summary
# ---------------------------------------------------------------------------
PAGE_COUNT=$(find "${OUTPUT_DIR}" -name '*.html' 2>/dev/null | wc -l | tr -d ' ')

echo "==> Done."
echo "    Archive:     ${DOCC_ARCHIVE}"
echo "    Static HTML: ${OUTPUT_DIR} (${PAGE_COUNT} HTML pages)"
echo ""
echo "    To preview locally:"
echo "      open ${OUTPUT_DIR}/index.html"
echo ""
echo "    To serve with a local web server:"
echo "      python3 -m http.server 8000 --directory ${OUTPUT_DIR}"
