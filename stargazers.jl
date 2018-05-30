using HTTP
import JSON
using ProgressMeter

# Load list of languages on GitHub
json = Array{String, 1}(JSON.parsefile("languages.json"))
language_name_regexp = r"[a-zA-Z\-]{1,30}\/([a-zA-Z\-]{1,30})"
languages = Dict{String, String}()
for lang in json
    m = match(language_name_regexp, lang)
    str = m.captures[1]
    languages[str] = lang
end

for (lang, name) in languages
    languages[lang] = "https://github.com/" * name
end

# Count stargazers
stargazers = Dict{String, Int64}()
stargazers_regexp = r"\d{2,10}(?= users starred this repository)"
println("Gettting the number of stargazers...")
progress = Progress(length(languages))
@sync for (lang, url) in languages
    @async begin
        request = HTTP.request("GET", url)
        body = String(request.body)
        m = match(stargazers_regexp, body)
        stargazers[lang] = parse(m.match)
        next!(progress)
    end
end

# Sort by number of stargazers
stargazers = sort(collect(stargazers), by=x->x[2], rev=true)

open("stargazers.md", "w") do f
    write(f, "| Language | Stargazers |\n")
    write(f, "| -------- | ---------- |\n")
    for (lang, number) in stargazers
        write(f, "| $(lang) | $(number) |\n")
    end
end

println("Output to stargazers.md")
println("Finished!")
