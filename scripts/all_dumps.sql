-- using sparql to get all graphs
-- The triple <graph> void:datadumpPattern "name" allows to configure the name for each graph

CREATE PROCEDURE DB.DBA.dumps_all_graphs () 
{
declare N int;
declare dataset, dump_dir varchar ;

N:=1;

for ( select graph_iri from ( sparql select distinct ?graph_iri where {graph ?graph_iri {?s a ?t}}) as sub ) do
{
    log_message(sprintf('Possible graph to dump %s', graph_iri)) ;
    IF ( strcontains(graph_iri, 'dataset') ) {
	-- set default value
	-- dump directory
        dump_dir := '/data/dumps/' ;
        dataset := sprintf(concat(dump_dir, 'dataset%i'), N); 
	for (select graph_iri_name, dataset_name from ( sparql select ?graph_iri_name ?dataset_name where {?graph_iri_name void:datadumpPattern ?dataset_name .  } ) as sub2 ) do 
	{
            log_message(graph_iri_name);
	    IF ( graph_iri = graph_iri_name ) {
	    -- overwrite with user defined value 
	       dataset := concat(dump_dir,dataset_name);
               log_message(dataset_name);
	    }
	}
        log_message(dataset);
        N := N +1;
        dump_one_graph(graph_iri, dataset);
        log_message(sprintf('graph %s dumped as dataset %s', graph_iri, dataset)) ;
    };
    
};

RETURN 1 ;

};


-- using builtin SPARQL_SELECT_KNOWN_GRAPHS
-- the _T version is the view which can be queried using sql
CREATE PROCEDURE DB.DBA.dumps_all_graphs2 () 
{
declare N int;
declare dataset varchar ;

N:=1;

for select graph_iri from DB.DBA.SPARQL_SELECT_KNOWN_GRAPHS_T do
{
    log_message(sprintf('Possible graph to dump %s', graph_iri)) ;
    IF ( strcontains(graph_iri, 'dataset') ) {
        dataset := sprintf('/data/dumps/dataset%i', N); 
        log_message(dataset);
        N := N +1;
        dump_one_graph(graph_iri, dataset);
        log_message(sprintf('graph %s dumped as dataset %s', graph_iri, dataset)) ;
    };
    
};

RETURN 1 ;

};


-- count the number of triples for a graph
CREATE PROCEDURE DB.DBA.counttrip (IN srcgraph VARCHAR) 
{
   RETURN ( SPARQL SELECT COUNT(*) WHERE { GRAPH `iri(?:srcgraph)` { ?s ?p ?o}} );
};


-- dump one graph in a series of files
CREATE PROCEDURE DB.DBA.dump_one_graph 
  ( IN  srcgraph           VARCHAR
  , IN  out_file           VARCHAR
  , IN  file_length_limit  INTEGER  := 1000000000
  )
  {
    DECLARE  file_name     VARCHAR
  ; DECLARE  env
          ,  ses           ANY
  ; DECLARE  ses_len
          ,  max_ses_len
          ,  file_len
          ,  triplescount
          ,  file_idx      INTEGER
  ; SET ISOLATION = 'uncommitted'
  ; max_ses_len  := 10000000
  ; file_len     := 0
  ; file_idx     := 1
  ; triplescount :=  CAST ( DB.DBA.counttrip (srcgraph ) AS INTEGER)
  ; file_name    := sprintf ('%s.ttl', out_file)
  ; IF (triplescount > max_ses_len ) 
       file_name    := sprintf ('%s_%02d.ttl', out_file, file_idx)
    
  ; string_to_file ( file_name || '.graph', 
                     srcgraph, 
                     -2
                   );
    string_to_file ( file_name, 
                     sprintf ( '# Dump of graph <%s>, as of %s (size %s) \n@base <> .\n', 
                               srcgraph, 
                               CAST (NOW() AS VARCHAR),
                               CAST (triplescount AS VARCHAR)
                             ), 
                     -2
                   )
  ; env := vector (dict_new (16000), 0, '', '', '', 0, 0, 0, 0, 0)
  ; ses := string_output ()

  ; FOR (SELECT * FROM ( SPARQL DEFINE input:storage "" 
                         SELECT ?s ?p ?o { GRAPH `iri(?:srcgraph)` { ?s ?p ?o } } 
                       ) AS sub OPTION (LOOP)) DO
      {
        http_ttl_triple (env, "s", "p", "o", ses);
        ses_len := length (ses);
        IF (ses_len > max_ses_len)
          {
            file_len := file_len + ses_len;
            IF (file_len > file_length_limit)
              {
                http (' .\n', ses);
                string_to_file (file_name, ses, -1);
		gz_compress_file (file_name, file_name||'.gz');
		file_delete (file_name);
                file_len := 0;
                file_idx := file_idx + 1;
                file_name := sprintf ('%s_%02d.ttl', out_file, file_idx);
        	log_message(sprintf('dumping file %s', file_name)) ;
                string_to_file ( file_name, 
                                 sprintf ( '# Dump of graph <%s>, as of %s (part %d) (size %s) \n@base <> .\n', 
                                           srcgraph, 
                                           CAST (NOW() AS VARCHAR), 
                                           file_idx,
                               		   CAST (triplescount AS VARCHAR) ),
                                 -2
                               );
                 env := VECTOR (dict_new (16000), 0, '', '', '', 0, 0, 0, 0, 0);
		 string_to_file ( file_name || '.graph', 
				     srcgraph, 
				     -2
				   );
		 string_to_file ( file_name, 
				     sprintf ( '# Dump of graph <%s>, as of %s (size %s) \n@base <> .\n', 
					       srcgraph, 
					       CAST (NOW() AS VARCHAR),
					       CAST (triplescount AS VARCHAR)
					     ), 
				     -2
				   );
              }
            ELSE
              string_to_file (file_name, ses, -1);
            ses := string_output ();
          }
      }
    IF (LENGTH (ses))
      {
        http (' .\n', ses);
        string_to_file (file_name, ses, -1);
	gz_compress_file (file_name, file_name||'.gz');
	file_delete (file_name);
      }
  }
;




