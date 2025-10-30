IETF Topology --> RDF (RFC8345)
RDFS schema, PWE3 static/dynamic instances, and IETF <--> NORIA alignment

Goal: a fully navigable SIMAP topology graph where every element is referenced via unique IRIs and explicit relations (e.g., network-ref, node-ref, tp-ref, link-ref, source-node, dest-node, source-tp, dest-tp).
Outcome: consistent schema + instance data for queries, validation, and visualisation.

✨ Built for demo - quick to run, easy to show.

🚦 Quick start (TL;DR)
	# 1) Open RDF4J Workbench (locally or publicly)
	# 2) Create repo ID
	# 3) Import files in this order:
	#    a) simap-rdfs-schema.ttl
	#    b) pwe3-static-topology.ttl
	#    c) pwe3-dynamic-topology.ttl
	#    d) Relations-IETF-Noria.ttl (optional alignment)
	# 4) SPARQL endpoint (use in SPARQLWorks):
	#    http://localhost:8080/rdf4j-server/repositories/...

📦 Repository structure
.
├─ schema/
│  └─ simap-rdfs-schema.ttl            # RDFS schema, single base path
├─ instances/
│  ├─ pwe3-static-topology.ttl         # Static PWE3 instance
│  └─ pwe3-dynamic-topology.ttl        # Dynamic PWE3 instance
├─ alignment/
│  └─ Relations-IETF-Noria.ttl         # Cross-model links: IETF <--> NORIA (optional)
└─ README.md

🧠 Data model highlights

	Single ontology base:
	http://www.huawei.com/ontology/ietf-network/... for all classes & properties (network, node, link, termination-point, supporting lists, source/dest, etc.).
	
	Instance paths use a stable data root, e.g.:
	http://www.huawei.com/data/network/<network-id>/node/<node-id>/...
	
	Explicit relations (examples):
	Networks: hasNetwork, hasNetworkTypes
	Links: hasSource --> source-node, source-tp; hasDest --> dest-node, dest-tp
	
	Supporting lists:
	supporting-network/network-ref,
	supporting-node/{network-ref,node-ref},
	supporting-termination-point/{network-ref,node-ref,tp-ref},
	supporting-link/{network-ref,link-ref}
	
	IETF <--> NORIA alignment (optional):
	Mappings in alignment/Relations-IETF-Noria.ttl let you traverse from IETF instance data to NORIA classes/instances for multi-model demos.

🧪 How to run (RDF4J Workbench)

	Open http://localhost:8080/rdf4j-workbench.
	
	Create repository --> Native store
	
	Repository ID: name
	
	Import (in this order):
	
	simap-rdfs-schema.ttl --> (Context: http://www.huawei.com/graph/schema)
	
	instances/pwe3-static-topology.ttl --> (Context: http://www.huawei.com/graph/instance/pwe3-static-topology)
	
	instances/pwe3-dynamic-topology.ttl --> (Context: http://www.huawei.com/graph/instance/pwe3-dynamic-topology)
	
	alignment/Relations-IETF-Noria.ttl (optional) --> (Context: http://www.huawei.com/graph/alignment)
	
	SPARQL endpoint (for tools):
	
	http://localhost:8080/rdf4j-server/repositories/name
	or a public server domain if you want to take the endpoint
	
	
	Sanity check (Workbench --> SPARQL):
	
	SELECT (COUNT(*) AS ?triples) WHERE { ?s ?p ?o }

🔎 Visualise with SPARQLWorks
	1. Local use (recommended)
	
	Download SPARQLWorks from https://github.com/danielhmills/sparqlworks and open sparqlworks.html locally (or serve via python -m http.server).
	
	Endpoint:
	
	http://localhost:8080/rdf4j-server/repositories/...
	
	
	Run CONSTRUCT queries (see below) for live graph visuals.
	
	If your browser blocks cross-origin calls, enable CORS on Tomcat (global conf/web.xml):
	
	<filter>
	  <filter-name>CorsFilter</filter-name>
	  <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>
	  <init-param><param-name>cors.allowed.origins</param-name><param-value>*</param-value></init-param>
	  <init-param><param-name>cors.allowed.methods</param-name><param-value>GET,POST,HEAD,OPTIONS</param-value></init-param>
	  <init-param><param-name>cors.allowed.headers</param-name><param-value>Content-Type,Accept,Origin,Authorization,Access-Control-Request-Method,Access-Control-Request-Headers</param-value></init-param>
	</filter>
	<filter-mapping><filter-name>CorsFilter</filter-name><url-pattern>/*</url-pattern></filter-mapping>
	
	
	Restart Tomcat afterwards.
	
	2. Public demo (optional)
	
	Put RDF4J Server behind a reverse proxy (Nginx/Apache) and expose
	https://<your-host>/rdf4j-server/repositories/name
	
	Make sure the proxy/app adds the CORS headers above.
	
	Alternative: use a tunnelling tool (e.g., LocalTunnel, Cloudflared). Ensure your corporate proxy policy allows it.

🧭 Example queries (ready for SPARQLWorks)

	Keep LIMIT small for readable graphs during demos.
	
	1) Root --> networks --> network-types
	
	CONSTRUCT {
	  <http://www.huawei.com/data/networks>
	    <http://www.huawei.com/ontology/ietf-network/networks/hasNetwork> ?net .
	  ?net a <http://www.huawei.com/ontology/ietf-network/networks/network> ;
	       <http://www.huawei.com/ontology/ietf-network/networks/network/hasNetworkTypes> ?nt .
	  ?nt  a <http://www.huawei.com/ontology/ietf-network/networks/network/network-types> .
	}
	WHERE {
	  OPTIONAL { <http://www.huawei.com/data/networks>
	    <http://www.huawei.com/ontology/ietf-network/networks/hasNetwork> ?net . }
	  OPTIONAL { ?net <http://www.huawei.com/ontology/ietf-network/networks/network/hasNetworkTypes> ?nt . }
	}

	2) Links with Source/Dest --> Termination Points

	CONSTRUCT {
	  ?link a <http://www.huawei.com/ontology/ietf-network/networks/network/link> ;
	        <http://www.huawei.com/ontology/ietf-network/networks/network/link/hasSource> ?src ;
	        <http://www.huawei.com/ontology/ietf-network/networks/network/link/hasDest>   ?dst .
	  ?src  <http://www.huawei.com/ontology/ietf-network/networks/network/link/source/source-tp> ?st .
	  ?dst  <http://www.huawei.com/ontology/ietf-network/networks/network/link/destination/dest-tp> ?dt .
	  ?st a <http://www.huawei.com/ontology/ietf-network/networks/network/node/termination-point> .
	  ?dt a <http://www.huawei.com/ontology/ietf-network/networks/network/node/termination-point> .
	}
	WHERE {
	  ?link a <http://www.huawei.com/ontology/ietf-network/networks/network/link> .
	  OPTIONAL { ?link <http://www.huawei.com/ontology/ietf-network/networks/network/link/hasSource> ?src .
	             OPTIONAL { ?src <http://www.huawei.com/ontology/ietf-network/networks/network/link/source/source-tp> ?st . } }
	  OPTIONAL { ?link <http://www.huawei.com/ontology/ietf-network/networks/network/link/hasDest>   ?dst .
	             OPTIONAL { ?dst <http://www.huawei.com/ontology/ietf-network/networks/network/link/destination/dest-tp> ?dt . } }
	}
	LIMIT 100

	3) Supporting-node
	CONSTRUCT {
	  ?snItem a <http://www.huawei.com/ontology/ietf-network/networks/network/node/supporting-node> ;
	          <http://www.huawei.com/ontology/ietf-network/networks/network/node/supporting-node/network-ref> ?nw ;
	          <http://www.huawei.com/ontology/ietf-network/networks/network/node/supporting-node/node-ref>    ?nref .
	  ?nw   a <http://www.huawei.com/ontology/ietf-network/networks/network> .
	  ?nref a <http://www.huawei.com/ontology/ietf-network/networks/network/node> .
	}
	WHERE {
	  ?snItem a <http://www.huawei.com/ontology/ietf-network/networks/network/node/supporting-node> .
	  OPTIONAL { ?snItem <http://www.huawei.com/ontology/ietf-network/networks/network/node/supporting-node/network-ref> ?nw . }
	  OPTIONAL { ?snItem <http://www.huawei.com/ontology/ietf-network/networks/network/node/supporting-node/node-ref>    ?nref . }
	}
	LIMIT 100

✅ Demo checklist
	- Schema loaded

	- Static & dynamic instances loaded (contexts separated)

	- Optional: IETF <--> NORIA alignment loaded for cross-model views

	- SPARQLWorks renders CONSTRUCT graphs cleanly
