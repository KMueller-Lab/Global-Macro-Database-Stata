{smcl}
{* *! version 2.1.0 29sep2026}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "gmd##syntax"}{...}
{viewerjumpto "Description" "gmd##description"}{...}
{viewerjumpto "Options" "gmd##options"}{...}
{viewerjumpto "Local storage, versions, and internet access" "gmd##storage"}{...}
{viewerjumpto "Examples" "gmd##examples"}{...}
{viewerjumpto "Stored results" "gmd##results"}{...}
{title:Title}

{phang}
{bf:gmd} {hline 2} Download the Global Macro Database and the underlying raw data, with version control

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:gmd} [{it:varlist}] [{cmd:,} {cmdab:ve:rsion(}{it:YYYY_MM|current|list}{cmd:)} {cmdab:cou:ntry(}{it:string|load|list}{cmd:)} {cmdab:y:ears(}{it:numlist}{cmd:)} {cmdab:inc:ome(}{it:string}{cmd:)} {cmdab:r:aw} {cmd:vars(}{it:load|list}{cmd:)} {cmdab:s:ources(}{it:string|load|list}{cmd:)} {cmd:cite(}{it:string|load}{cmd:)} {cmd:print(}{it:string}{cmd:)} {cmdab:n:etwork(}{it:string}{cmd:)} {cmd:save(}[{it:folder}] [{cmd:,} {cmd:replace}]{cmd:)} {cmd:clear}]

{marker description}{...}
{title:Description}

{pstd}
This command downloads and loads the Global Macro Database (GMD), the
world's most comprehensive repository of macroeconomic statistics. Users
can specify which version to load, which variables to keep, and filter for
specific countries, years, and income groups. Users can also download the underlying data, which means easy
access to hundreds of cleaned data sources from the original providers. The dataset is
updated quarterly, with occasional patches; versions follow the naming
convention YYYY_MM. Like {cmd:use}, the command refuses to replace unsaved
data in memory unless the {cmd:clear} option is specified.

{pstd}
By default the dataset is downloaded on every call and nothing is written to
disk. Use {cmd:save()} to keep a copy in a folder of your choice; later calls
then load that copy instead of downloading. See
{help gmd##storage:Local storage, versions, and internet access} below.

{pstd}
For a summary of what changed between data versions, see the release notes at
{browse "https://www.globalmacrodata.com/data#release-notes"}.

{pstd}
When a {it:varlist} is specified, the command drops, for each country, the
years before the first year in which any of the specified variables is
available. Later years in which all specified variables are missing are
kept, so the panel has no internal gaps. Variables that are
entirely missing in the returned sample (for example a series that does not
exist for the requested country) are dropped as well, so check
{cmd:r(varlist)} if later code relies on a particular variable being present.

{pstd}
Variable names in {it:varlist} are matched without regard to case
({cmd:gmd ngdp} loads {cmd:nGDP}) and may contain the wildcards {cmd:*} and
{cmd:?} ({cmd:gmd *_GDP}). Abbreviations are not accepted. The keywords
{cmd:list}, {cmd:load}, and {cmd:current}, as well as source names and ISO3
codes, are likewise case-insensitive.

{marker options}{...}
{title:Options}

{phang}
{cmd:version(}{it:YYYY_MM|current|list}{cmd:)} specifies which version of the dataset to load (e.g., 2025_03).
The GMD is released on a quarterly basis.
Specifying a version allows for reproducibility of empirical results; the
loaded version is always printed at the end of the output.
Type {cmd:version(current)} to load the most recent version explicitly; the output and {cmd:r(version)} then show the version this resolved to.
To see a list of all available historical versions, type {cmd:gmd, version(list)}.
For a summary of changes between versions, see {browse "https://www.globalmacrodata.com/data#release-notes":the release notes}.
If a local copy of the requested version exists (see {cmd:save()}), it is loaded without any internet access; otherwise the version is downloaded.
A requested version is never replaced by another one: if it is neither stored locally nor downloadable, {cmd:gmd} stops with an error.
{p_end}

{phang}
{cmd:country(}{it:string|load|list}{cmd:)} filters the data to only include one or several countries, as specified using ISO3 codes 
(e.g., USA, GBR). Case-insensitive. To see a list of all ISO3 codes, type {cmd:gmd, country(list)}.{p_end}

{phang2}
Type {cmd:gmd, country(load)} to load the country reference table into memory instead of the dataset. This table maps each ISO3 code to its country name (and related identifiers), and is useful for merging GMD codes with your own data.{p_end}

{phang}
{cmd:years(}{it:numlist}{cmd:)} restricts the loaded data to the specified years. Accepts any Stata {it:numlist}, for example {cmd:years(2000/2020)}, {cmd:years(1990 2000 2010)}, or {cmd:years(2000/2020 2025)}. The filter is applied in memory to the loaded panel after the data and any country selection. It works with the main dataset and with {cmd:raw} data.{p_end}

{phang}
{cmd:income(}{it:string}{cmd:)} keeps only countries in the requested World Bank income group(s): {cmd:High income}, {cmd:Upper middle income}, {cmd:Lower middle income}, or {cmd:Low income}. Matching is case-insensitive and common abbreviations are accepted (e.g. {cmd:H}, {cmd:UM}, {cmd:LM}, {cmd:L}, or {cmd:HIC}, {cmd:UMC}, {cmd:LMC}, {cmd:LIC}). Separate several groups with spaces or commas, e.g. {cmd:income(High income, Upper middle income)} or {cmd:income(H UM)}. This option is only available for the main dataset (the income classification is not present in {cmd:raw} or {cmd:sources()} data).{p_end}

{phang}
{cmd:raw} loads all raw data sources for a single specified variable. Requires specifying exactly one variable in {it:varlist}.
This option is implicit when using {cmd:sources()}.{p_end}

{phang}
{cmd:vars(}{it:load|list}{cmd:)} allows users to see a list of available variables with definitions and units. Type {cmd:gmd, vars(list)} to see a list or {cmd:gmd, vars(load)} to load them into the data frame.{p_end}

{phang}
{cmd:sources(}{it:string|load|list}{cmd:)} loads cleaned raw data for a specific source (e.g., IMF_IFS). Requires specifying exactly one source name. 
Type {cmd:gmd, sources(list)} to see a list or {cmd:gmd, sources(load)} to load them into the data frame.
You can specify a {it:varlist} with this option to load only specific variables from that source, and {cmd:country()} to keep only some countries.
Source datasets are not archived by version: {cmd:sources()} always returns the latest available file and cannot be combined with {cmd:version()}.
To obtain the source values that entered a given release, use {cmd:raw} with {cmd:version()}, e.g. {cmd:gmd nGDP, raw version(2025_09)}, which returns one column per source for that variable.{p_end}

{phang}
{cmd:cite(}{it:string|load}{cmd:)} generates BibTeX citations for a specific source key, which can be easily copy-pasted.
Type {cmd:gmd, cite(load)} to load the full list of sources and their citation keys into memory.{p_end}

{phang}
{cmd:print(}{it:GMD|Stata}{cmd:)} displays APA and BibTeX style citations for the {cmd:GMD} database or the {cmd:gmd} Stata command. This is primarily used by the command's interactive links.{p_end}

{phang}
{cmd:network(}{it:string}{cmd:)} bypasses the internet connection check and forces the command to attempt a connection. Use this if the automatic check fails but you have internet access. Any argument switches the bypass on ({cmd:network(yes)} is the convention); omit the option to leave the check in place.{p_end}

{phang}
{cmd:save(}[{it:folder}] [{cmd:,} {cmd:replace}]{cmd:)} downloads the selected version and saves it locally so it can be reloaded without downloading again. Specify a full path to an existing folder, e.g. {cmd:save("/full/path")}, or {cmd:save()} to use the current working directory. The file is named {cmd:GMD_}{it:YYYY_MM}{cmd:.dta}, where {it:YYYY_MM} is the data version (e.g. {cmd:GMD_2025_09.dta}). If that file already exists, {cmd:gmd} stops with an error unless {cmd:replace} is added, e.g. {cmd:save("/full/path", replace)} or {cmd:save(replace)}. A relative folder, e.g. {cmd:save("data")}, is taken relative to the current working directory and remembered as the full path. {cmd:save()} applies only when loading the main dataset; it cannot be combined with {cmd:raw}, {cmd:sources()}, {cmd:cite()}, {cmd:vars()}, {cmd:country(list)}, {cmd:country(load)}, or {cmd:version(list)}. The chosen folder is remembered for future {cmd:gmd} calls; see {help gmd##storage:Local storage, versions, and internet access}.{p_end}

{phang}
{cmd:clear} permits replacing the data currently in memory. Like Stata's own {cmd:use}, {cmd:gmd} refuses to load data when there are unsaved changes in memory; specify {cmd:clear} to proceed and discard them. Data returned by {cmd:gmd} itself is not counted as unsaved work, so consecutive {cmd:gmd} calls do not need {cmd:clear}. Display-only calls such as {cmd:gmd, vars(list)} never touch the data in memory.{p_end}

{marker storage}{...}
{title:Local storage, versions, and internet access}

{pstd}
{bf:Where the data is stored.} By default {cmd:gmd} downloads the dataset on
every call and writes nothing to disk. {cmd:save()} stores the selected
version as {cmd:GMD_}{it:YYYY_MM}{cmd:.dta} in the folder you name (or the
current working directory) and records that folder in a small text file,
{cmd:gmd_datadir.txt}, in your Stata PERSONAL directory (type {cmd:sysdir} to
see where that is). Nothing is stored in the PLUS or other system
directories. Delete {cmd:gmd_datadir.txt} to make {cmd:gmd} forget the folder.

{pstd}
{bf:Which copy is loaded.} On every call {cmd:gmd} looks for local data before
downloading, in this order: (1) the current working directory, if it contains
a GMD file; (2) the folder recorded by the last {cmd:save()}. Only files named
exactly {cmd:GMD_}{it:YYYY_MM}{cmd:.dta} count; other names, such as
{cmd:GMD_backup.dta}, are ignored. Without {cmd:version()}, the most recent
version in the first of these folders that holds one is loaded and the
message "Loading the local version (GMD_{it:YYYY_MM})" is shown; if a newer
version exists online, a note says so. With {cmd:version()}, the file for
that version is looked for in the working directory and then in the
remembered folder, and downloaded if neither holds it (without being saved
unless {cmd:save()} is given).
The loaded version is always printed at the end of the output.

{pstd}
{bf:Working with several projects or versions.} Because the file name carries
the version, several versions can sit side by side in one folder, and each
project can keep its own copy next to its do-files. The recommended workflow
for a reproducible project is to change to the project folder, run
{cmd:gmd, version(}{it:YYYY_MM}{cmd:) save()} once to store that version
there, and then pin the version in every call in the do-files, e.g.
{cmd:gmd nGDP pop, version(}{it:YYYY_MM}{cmd:)}. Because the working
directory is checked first, each project loads its own file and projects
never interfere with each other. Only the {it:last} folder passed to
{cmd:save()} is remembered; a project that relies on the remembered folder
rather than the working directory should therefore pin {cmd:version()} so
that a version that is absent locally is downloaded rather than silently
replaced by another.

{pstd}
{bf:When internet access is needed.} A call that pins a version which is
stored locally, e.g. {cmd:gmd nGDP, version(2025_09)}, reads that file and
does not use the internet at all. Every other call first fetches the list of
available versions to validate {cmd:version()} and to check for updates.
Internet access is required to download the dataset (any call without a local
copy, or with {cmd:save()}), and for {cmd:raw}, {cmd:sources()},
{cmd:cite()}, {cmd:vars()}, and {cmd:country(list)} or {cmd:country(load)},
which read helper files from the GMD server. Without internet access,
{cmd:gmd} reports that the version list could not be reached. If no version
is pinned (or {cmd:version(current)} is given), it loads the most recent
local copy from the folders above if one exists and stops with an error
otherwise. If a version is pinned and that file is not stored locally, it
stops with an error rather than loading a different version. If the version
check fails although you are online, add {cmd:network(yes)}.

{marker examples}{...}
{title:Examples}

{phang}1. Load the latest full dataset:{p_end}
{phang2}{cmd:. gmd}

{phang}2. Save the latest version in the current working directory and load it; later calls to {cmd:gmd} in this folder reuse the file:{p_end}
{phang2}{cmd:. gmd, save()}

{phang}2b. Save a specific version in a project folder, overwriting an existing file:{p_end}
{phang2}{cmd:. gmd, version(2025_09) save("/full/folder/path", replace)}

{phang}3. Load specific variables (e.g., Nominal GDP and Population):{p_end}
{phang2}{cmd:. gmd nGDP pop}

{phang}4. Load data for a specific country (e.g., Singapore):{p_end}
{phang2}{cmd:. gmd, country(SGP)}

{phang}5. Load a specific vintage (e.g., September 2025) for reproducibility:{p_end}
{phang2}{cmd:. gmd, version(2025_09)}

{phang}6. Access raw data for a specific variable:{p_end}
{phang2}{cmd:. gmd nGDP, raw}

{phang}7. Access data from a specific source (e.g., IMF World Economic Outlook):{p_end}
{phang2}{cmd:. gmd, sources(IMF_WEO)}

{phang}8. Restrict to a range of years (e.g., 2000 to 2020):{p_end}
{phang2}{cmd:. gmd nGDP, years(2000/2020)}

{phang}9. Keep only high-income countries:{p_end}
{phang2}{cmd:. gmd nGDP, income("High income")}

{phang}10. Combine filters: upper- and lower-middle-income countries since 2010:{p_end}
{phang2}{cmd:. gmd nGDP pop, income(UM LM) years(2010/2024)}

{marker results}{...}
{title:Stored results}

{pstd}
When {cmd:gmd} loads data into memory (the main dataset, {cmd:raw}, or
{cmd:sources()}), it stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of variables{p_end}
{synopt:{cmd:r(verified)}}1 if the file carried a release signature and it was confirmed, 0 if it carried none (main dataset only){p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(version)}}data version that was loaded, as {it:YYYY_MM} (main dataset and {cmd:raw}){p_end}
{synopt:{cmd:r(datasignature)}}data signature of the full release file, computed before any filtering (main dataset only); see {helpb datasignature}{p_end}
{synopt:{cmd:r(sources)}}name of the source that was loaded ({cmd:sources()} only){p_end}
{synopt:{cmd:r(varlist)}}variables in memory other than {cmd:ISO3}, {cmd:year}, {cmd:id}, and {cmd:countryname}{p_end}
{synopt:{cmd:r(origin)}}{cmd:local} if the data were read from a saved copy, {cmd:download} otherwise{p_end}
{synopt:{cmd:r(filename)}}full path of the local file that was read or written, if any{p_end}
{p2colreset}{...}

{pstd}
A do-file can use these to guard against loading the wrong vintage, e.g.
{cmd:assert "`r(version)'" == "2025_09"}.

{pstd}
{bf:Data signatures.} Release files may carry the version they belong to and a
data signature set when the file was built. {cmd:gmd} checks both on the full
file before filtering and stops with an error if a local file was renamed to
another version or edited after its release; {cmd:r(verified)} is then 1 and
the signature is shown in the output. {cmd:r(datasignature)} is returned for
every release, signed or not, so it can be recorded in a do-file or paper and
compared later: the same signature means the same data. The signature is
removed from a filtered result, since it describes the full release.

{title:Authors}

{pstd}
Mohamed Lehbib{break}
National University of Singapore{break}
Email: {browse "mailto:lehbib@u.nus.edu":lehbib@u.nus.edu}{break}

{pstd}
Karsten Müller{break}
National University of Singapore{break}
Email: {browse "mailto:kmueller@nus.edu.sg":kmueller@nus.edu.sg}{break}
Website: {browse "https://www.karstenmueller.com"} 

{title:Documentation}

{pstd}
You can find the {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata/blob/main/Global_Macro_Database_Stata.pdf":paper} describing the package in detail in this repository.

{pstd}
You can find the {browse "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_TA.pdf":Technical Appendix} on the official {browse "https://www.globalmacrodata.com":website}.

{pstd}
Please visit this {browse "https://github.com/KMueller-Lab/Global-Macro-Database":repository} to access the GMD source code.

{pstd}
Please visit this {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata":repository} to access the Stata package source code.

{pstd}
Please contact {browse "mailto:lehbib@u.nus.edu":lehbib@u.nus.edu} if you have any questions or suggestions.

{title:Citation}

{pstd}
When using the Global Macro Database, please cite the following NBER Working Paper:

{pstd}
Müller, K., Xu, C., Lehbib, M., & Chen, Z. (2025). The Global Macro Database: A New International Macroeconomic Dataset (NBER Working Paper No. 33714).

{pstd}
BibTeX:

{phang}
{cmd:@techreport{c -(}mueller2025global,}{break}
{cmd:    title = {c -(}{c -(}The Global Macro Database: A New International Macroeconomic Dataset{c )-}{c )-},}{break}
{cmd:    author = {c -(}M{c -(}\"u{c )-}ller, Karsten and Xu, Chenzi and Lehbib, Mohamed and Chen, Ziliang{c )-},}{break}
{cmd:    institution = {c -(}National Bureau of Economic Research{c )-},}{break}
{cmd:    type = "Working Paper",}{break}
{cmd:    series = "Working Paper Series",}{break}
{cmd:    number = "33714",}{break}
{cmd:    year = "2025",}{break}
{cmd:    month = "April",}{break}
{cmd:    doi = {c -(}10.3386/w33714{c )-},}{break}
{cmd:    URL = "http://www.nber.org/papers/w33714",}{break}
{cmd:{c )-}}

{pstd}
If you use this Stata command, please additionally cite:

{pstd}
Lehbib, M. & Müller, K. (2025). gmd: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database. Working Paper.

{pstd}
BibTeX:

{phang}
{cmd:@techreport{c -(}lehbib2025gmd,}{break}
{cmd:    title = {c -(}{c -(}GMD: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database{c )-}{c )-},}{break}
{cmd:    author = {c -(}Mohamed Lehbib and Karsten M{c -(}\"u{c )-}ller{c )-},}{break}
{cmd:    year = {c -(}2025{c )-},}{break}
{cmd:    type = {c -(}Working Paper{c )-}}{break}
{cmd:{c )-}}

{title:License & Terms of Use}

{pstd}
The data is available for {bf:non-commercial use only}. By using this package, you agree to the terms of use outlined on the {browse "https://www.globalmacrodata.com":GMD website}.

{pstd}
For license enquiries, please email {browse "mailto:kmueller@globalmacrodata.com":kmueller@globalmacrodata.com}.

{title:Version}

{pstd}
This is version 2.1.0 of {cmd:gmd}.
{p_end}