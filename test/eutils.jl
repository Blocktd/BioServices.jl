
@testset "EUtils" begin
    @testset "einfo" begin
        res = einfo(db="pubmed")
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)
        @test nodename(elements(root(parsexml(res.body)))[1]) != "ERROR"
    end

    @testset "esearch" begin
        res = esearch(db="pubmed", term="asthma")
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)
        @test nodename(elements(root(parsexml(res.body)))[1]) != "ERROR"
    end

    @testset "epost" begin
        ctx = Dict()
        res = epost(ctx, db="protein", id="NP_005537")
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)
        @test haskey(ctx, :WebEnv)
        @test haskey(ctx, :query_key)
    end

    @testset "esummary" begin
        # esummary doesn't seem to support accession numbers
        res = esummary(db="protein", id="15718680,157427902,119703751")
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)
        @test nodename(elements(root(parsexml(res.body)))[1]) != "ERROR"

        res = esummary(db="protein", id=["15718680", "157427902", "119703751"])
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)
        @test nodename(elements(root(parsexml(res.body)))[1]) != "ERROR"

        # esearch then esummary
        query = "asthma[mesh] AND leukotrienes[mesh] AND 2009[pdat]"
        ctx = Dict()
        res = esearch(ctx, db="pubmed", term=query, usehistory=true, retmode="xml")
        @test res.status == 200
        res = esummary(ctx, db="pubmed")
        @test res.status == 200

        ctx = Dict()
        res = esearch(ctx, db="pubmed", term=query, usehistory=true, retmode="json")
        @test res.status == 200
        res = esummary(ctx, db="pubmed")
        @test res.status == 200
    end

    @testset "efetch" begin
        res = efetch(db="nuccore", id="NM_001178.5", retmode="xml", idtype="acc")
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)

        # epost then efetch
        ctx = Dict()
        res = epost(ctx, db="protein", id="NP_005537")
        @test res.status == 200
        res = efetch(ctx, db="protein", retmode="xml")
        @test res.status == 200
    end

    @testset "elink" begin
        res = elink(dbfrom="protein", db="gene", id="NM_001178.5")
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)
    end

    @testset "egquery" begin
        res = egquery(term="asthma")
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)
    end

    @testset "espell" begin
        res = espell(db="pmc", term="fiberblast cell grwth")
        @test res.status == 200
        @test startswith(Dict(res.headers)["Content-Type"], "text/xml")
        @test isa(parsexml(res.body), EzXML.Document)
        doc = parsexml(res.body)
        spelled_query = elements(root(doc))[4]
        replaced_spell = nodecontent(elements(spelled_query)[4])
        @test replaced_spell == "growth"
    end

    @testset "ecitmatch" begin
        res = ecitmatch(
            db="pubmed",
            retmode="xml",
            bdata="proc natl acad sci u s a|1991|88|3248|mann bj|Art1|")
        @test res.status == 200
        # ECitMatch is mysterious: it returns a plain text data even though it
        # requires retmode="xml".
        # @show res.headers["Content-Type"]
    end
end
