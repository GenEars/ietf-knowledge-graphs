IETF-RDFS-Generated
Auto-generated RDFS for IETF network models + alignment to NORIA 0.3 (via the Simple Alignment Ontology).
Use this repo to explore schemas, run checks, and integrate the models into a knowledge graph. ✨
---
🔎 What’s inside
.
├─ simap-rdfs-schema.ttl      # RDFS schema for IETF networks (classes & properties)
└─ relations-IETF-Simap-Noria.ttl       # Alignment: IETF <--> NORIA (Simple Alignment Ontology)

🚀 Overview

Traditional YANG-to-RDF conversions describe syntax rather than semantics - they define how elements are structured but not how they relate.
This generator takes those YANG-derived RDF files and builds a semantic schema view that introduces explicit:

Classes – derived from YANG containers/lists (e.g. Network, Node, Link, TerminationPoint)

Object Properties – derived from leafref connections and structural containment

Datatype Properties – derived from leaf nodes like IDs or names

Annotations – including rdfs:label, rdfs:comment, and provenance via prov:wasDerivedFrom

Key Features:

 - Automatic mapping from YANG/YIN RDF → RDFS/OWL

 - Class detection for yin:List and yin:Container

 - Relationship inference:

    - Generates ObjectProperties from leafref connections (e.g. network-ref, leaf-ref)

    - Adds DatatypeProperties for IDs and names (network-id, node-id, etc.)

- Structural relations (added manually when no leafref exists):

    - hasNetwork, hasNetworkType, hasSource, hasDest

- Preserves YANG path hierarchy in prov:wasDerivedFrom for full traceability

- Produces a clean Turtle (.ttl) file ready for SPARQL exploration or visualisation in Blazegraph, RDF4J, or Graph Notebook.

	- Clean RDFS classes: Network, Node, Link, Termination-Point, etc.
	- Properties: IDs, source/destination, supporting refs, containers.
	- Uses the Simple Alignment Ontology (align:).
	- Maps IETF elements to noria: terms using align:equals, align:similar, align:lessGeneral.
 
🚀 Quick start
1.	Option A - Load into a triple store
	Create or open a dataset.
	Load files in this order:
	1) simap-rdfs-schema.ttl
	2) relations-IETF-Simap-Noria.ttl
	Run the sample SPARQL queries below to explore the mappings.
2.	Option B - Work in Python (rdflib)
from rdflib import Graph
g = Graph()
g.parse("simap-rdfs-schema.ttl", format="turtle")
g.parse("relations-IETF-Simap-Noria.ttl", format="turtle")

q = """
PREFIX align: <http://knowledgeweb.semanticweb.org/heterogeneity/alignment#>
PREFIX noria: <https://w3id.org/noria/ontology/>
SELECT ?ietf ?rel ?noria WHERE {
  ?ietf ?rel ?noria .
  FILTER(STRSTARTS(STR(?rel), STR(align:)))
}
ORDER BY ?ietf
LIMIT 25
"""
for row in g.query(q):
    print(row)
🧭 How to navigate
	- Schema first? Open simap-rdfs-schema.ttl to view classes and properties (labels + comments).
	- Cross-ontology view? Open relations-IETF-Simap-Noria.ttl and scan by predicate strength:
	  - align:equals --> strongest
	  - align:similar --> close semantic overlap
	  - align:lessGeneral --> IETF term is narrower than the NORIA term
	- Follow references: search for *-ref (network-ref, node-ref, link-ref, tp-ref) to see how leafrefs connect to noria concepts.

🧩 What you can do
	- Validate the IETF model with SHACL/SPARQL shape checks.
	- Integrate IETF instances into a NORIA-based knowledge graph using the alignment.
	- Query across models via align:* predicates to bridge vocabularies.
	- Extend with extra modules (e.g., L2/L3 types) and add new align: statements.
🛠 Tips
	- Keep IETF schema files read-only. Put custom mappings in separate TTLs.
	- Prefer mapping strength in this order: equals --> similar --> lessGeneral.
	- Document any design decisions at the top of your alignment file.
	- Use clear commit messages when updating alignments.
📚 References
Simple Alignment Ontology: http://knowledgeweb.semanticweb.org/heterogeneity/alignment#
NORIA Ontology: https://w3id.org/noria/ontology/
📬 Contributing
PRs are welcome for:
- New or refined mappings
- Examples & tests
- Fixes to labels/comments

