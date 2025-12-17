## Ejemplos de consultas SPARQL sobre el grafo de conocimiento cancer_therapy

library(SPARQL)
endpoint <- "http://dayhoff.inf.um.es:3042/blazegraph/namespace/cancer_therapy/sparql"

# Consulta 1: Listar todos los fármacos y las proteínas a las que se unen que son codificadas por genes asociados a una enfermedad
# Esta consulta conecta fármacos con proteínas, luego con los genes que las codifican, y finalmente con las enfermedades asociadas a esos genes.
# Es útil para identificar rutas terapéuticas completas y comprobar si un medicamento tiene sentido biológico en función de sus dianas moleculares.

query1 <- "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ns0:  <http://cancer_therapy.esd.es/>
PREFIX mondo: <http://purl.obolibrary.org/obo/MONDO_>

SELECT
  ?drug ?drugLabel ?protein ?proteinLabel ?gene ?geneLabel ?disease ?diseaseLabel
  
WHERE {
  ?drug a ns0:Drug ;
        rdfs:label ?drugLabel ;
        ns0:binds ?protein .

  ?protein rdfs:label ?proteinLabel .

  ?gene a ns0:Gene ;
        rdfs:label ?geneLabel ;
        ns0:encodes ?protein ;
        ns0:associatedWith ?disease .

  ?disease a ns0:Disease ;
           rdfs:label ?diseaseLabel .
}
"
results1 <- SPARQL(endpoint, query1)$results
# Para quitar los <|> de los URIs en la salida hay que hacer lo siguiente:
results1$drug <- gsub("[<>]", "", results1$drug)
results1$protein <- gsub("[<>]", "", results1$protein)
results1$gene <- gsub("[<>]", "", results1$gene)
results1$disease <- gsub("[<>]", "", results1$disease)
print(results1)


# Consulta 2: Encontrar todos los fármacos que tratan el cáncer de mama y las proteínas que inhiben o a las que se unen
# Esta consulta devuelve los fármacos cuyo objetivo terapéutico es el cáncer de mama, y muestra si se unen o inhiben proteínas concretas.
# Permite entender los mecanismos moleculares de los tratamientos disponibles y comparar la forma en que actúan.

query2 <- "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ns0: <http://cancer_therapy.esd.es/>
PREFIX mondo: <http://purl.obolibrary.org/obo/MONDO_>

SELECT ?diseaseLabel ?drug ?drugLabel ?interaction ?protein ?proteinLabel 
WHERE {
  ?drug a ns0:Drug ;
        rdfs:label ?drugLabel ;
        ns0:treats mondo:0004989 .

  mondo:0004989 rdfs:label ?diseaseLabel .

  {
    ?drug ns0:binds ?protein .
    BIND(\"binds\" AS ?interaction)
  }
  UNION
  {
    ?drug ns0:inhibits ?protein .
    BIND(\"inhibits\" AS ?interaction)
  }

  ?protein rdfs:label ?proteinLabel .
}

"

results2 <- SPARQL(endpoint, query2)$results
# Quitar los <|> de los URIs en la salida
results2$drug <- gsub("[<>]", "", results2$drug)
results2$protein <- gsub("[<>]", "", results2$protein)
print(results2)


# Consulta 3: Número de fármacos disponibles por enfermedad
# Esta consulta calcula cuántos fármacos distintos están asociados al tratamiento de cada enfermedad
# presente en el grafo, utilizando la relación terapéutica definida entre fármacos y enfermedades.
# Es útil para obtener una visión global y comparativa de la cobertura terapéutica de las distintas
# patologías modeladas, sin entrar en el detalle de los mecanismos moleculares implicados.

query3 <- "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ns0:  <http://cancer_therapy.esd.es/>

SELECT ?disease ?diseaseLabel (COUNT(DISTINCT ?drug) AS ?numDrugs)
WHERE {
  ?drug a ns0:Drug ;
        ns0:treats ?disease .
  ?disease a ns0:Disease ;
           rdfs:label ?diseaseLabel .
}
GROUP BY ?disease ?diseaseLabel
ORDER BY DESC(?numDrugs) ?diseaseLabel

"
results3 <- SPARQL(endpoint, query3)$results
results3$disease <- gsub("[<>]", "", results3$disease)
print(results3)


# Consulta 4: Análisis gen-céntrico en linfoma no Hodgkin
# Identifica genes asociados a la enfermedad, las proteínas que codifican y los fármacos que actúan sobre dichas proteínas,
# integrando información genética, molecular y terapéutica.

query4 <- "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ns0:  <http://cancer_therapy.esd.es/>
PREFIX mondo: <http://purl.obolibrary.org/obo/MONDO_>

SELECT DISTINCT
  ?diseaseLabel ?gene ?geneLabel ?protein ?proteinLabel ?drug ?drugLabel
WHERE {

  BIND(mondo:0018908 AS ?disease)
  ?disease rdfs:label ?diseaseLabel .

  ?gene a ns0:Gene ;
        rdfs:label ?geneLabel ;
        ns0:associatedWith ?disease ;
        ns0:encodes ?protein .

  ?protein rdfs:label ?proteinLabel .

  ?drug a ns0:Drug ;
        rdfs:label ?drugLabel .

  { ?drug ns0:binds ?protein . }
  UNION
  { ?drug ns0:inhibits ?protein . }
}

"
results4 <- SPARQL(endpoint, query4)$results
results4$drug <- gsub("[<>]", "", results4$drug)
results4$gene <- gsub("[<>]", "", results4$gene)
results4$protein <- gsub("[<>]", "", results4$protein)
print(results4)


# Consulta 5: Recuperar todas las enfermedades tratadas por un fármaco y listar todos los genes y proteínas implicadas
# Para cada fármaco, se obtienen las enfermedades que trata y, si existen, los genes y proteínas relacionados con su mecanismo de acción.
# Esta información es valiosa para documentar la acción de un tratamiento y para estudiar posibles usos alternativos del mismo.

query5 <- "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ns0:  <http://cancer_therapy.esd.es/>
PREFIX mondo: <http://purl.obolibrary.org/obo/MONDO_>

SELECT DISTINCT
  ?disease ?diseaseLabel ?drug ?drugLabel ?protein ?proteinLabel ?gene ?geneLabel
  
WHERE {
  ?drug a ns0:Drug ;
        rdfs:label ?drugLabel ;
        ns0:treats ?disease .

  ?disease a ns0:Disease ;
           rdfs:label ?diseaseLabel .

  OPTIONAL {
    { ?drug ns0:binds ?protein . }
    UNION
    { ?drug ns0:inhibits ?protein . }

    ?protein rdfs:label ?proteinLabel .

    ?gene a ns0:Gene ;
          rdfs:label ?geneLabel ;
          ns0:encodes ?protein .
  }
}
ORDER BY ?diseaseLabel ?drugLabel ?proteinLabel
"
results5 <- SPARQL(endpoint, query5)$results
results5$disease <- gsub("[<>]", "", results5$disease)
results5$drug <- gsub("[<>]", "", results5$drug)
results5$gene <- gsub("[<>]", "", results5$gene)
results5$protein <- gsub("[<>]", "", results5$protein)
print(results5)

# Fin del script

