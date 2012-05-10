
require(RCurl)
require(stringr)
require(RJSONIO)
library(igraph)
library(reshape)
library(tm)
library(wordcloud)
require(RColorBrewer)

# CC-BY mhawksey
# This script processes data collected using this google spreadsheet template https://docs.google.com/spreadsheet/ccc?key=0AqGkLMU9sHmLdE9HSDNOMmxneFpUZHdZd2pnS1BUb1E
# and processes the data, putting results back into the spreadsheet and generating data files for this template http://hawksey.info/labs/compare/score-ukoer.html
# Read more about this at http://mashe.hawksey.info/2012/05/visual-compare-twitter-accounts


# variables you'll need to edit
# project name (prefixed to output files)
project = "SCORE-UKOER"
# google spreadsheet key
key = "google-spreadsheet-key"
# Publsih as service url
serviceUrl='publish-as-service-url'
# A secret set in the Script Editor of the spreadsheet to prevent unauthorised data entry
secret='passphrase'
# define a list of accounts you want to compare 
subgroup = c('ukoer', 'SCOREProject')



# sheet number (gid) of the vertices sheet
gid = 46
# query returning columns id, screen_name, friend_ids and description 
query = 'select A, B, X, P'
#query returning screen_name  betweenness_centrality	degree_in	followers_count	group	belongs_to	profile_image_url
queryB = "select B, F, D, M, I, J, S where J <>''"

# function to get data from spreadsheet
gsqAPI = function(key,query,gid=0){
  url=paste( sep="",'http://spreadsheets.google.com/tq?', 'tqx=out:csv','&tq=', curlEscape(query), '&key=', key, '&gid=', gid)
  return( read.csv( url,header =T ) ) 
}


# get data collected in google spreadsheet 
tab = gsqAPI(key,query,gid)
# if the line above throws a warning copy the url included in the message to download csv data and put 
# in your working directory, uncomment the next line and read the data locally
tab = read.csv( 'data.csv',header =T )

names = c("id", "name", "links" , "description")
colnames(tab) <- names

# Next 4 lines come for the awsesome jbaums and stackoverflow http://stackoverflow.com/a/9105852/1027723
conns <- function(name, links) {
  paste(name, tab$name[tab$id %in% as.numeric(unlist(strsplit(gsub('\\[|\\]',",",gsub('\'|\"','', links)),',')))], sep=',')
}

connections <- data.frame(unlist(mapply(conns, tab$name, tab$links,SIMPLIFY=FALSE)))
connections <- str_split_fixed(connections[,1], fixed(","), 2)

data <- as.data.frame(connections)
toBeRemoved<-which(data[,2]=="")
data<-data[-toBeRemoved,]
summary(data)
#data <- data[!is.na(data[,2]),]
#summary(data)
edcolNames <- c("target", "source")
colnames(data) <- edcolNames
write.table(data,file=paste(project,"-edges.csv"),sep=",",row.names=F)
edges =  toJSON(data)
#data <- read.csv( "Myfile [Edges].csv",header =T )
g <- graph.data.frame(data, directed = T)


# calculate some stats
betweenness_centrality <- betweenness(g,v=V(g),directed = TRUE)
eigenvector_centrality<-evcent(g)
pagerank<-page.rank(g)$vector
degree<-degree(g, v=V(g), mode = "total")
degree_in<-degree(g, v=V(g), mode = "in")
degree_out<-degree(g, v=V(g), mode = "out")
screen_name<-V(g)$name

memberships <- list()
### spinglass.community
sc <- spinglass.community(g, spins=10)
memberships$Spinglass <- sc$membership
head(sc)
### walktrap.community
wt <- walktrap.community(g, modularity=TRUE)
wmemb <- community.to.membership(g, wt$merges,
                                 steps=which.max(wt$modularity)-1)
head(wmemb)

# choose which community grouping you want to push back to the spreadsheet
group <- sc$membership
#group <- wmemb$membership

# bind into matrice
datagrid<-data.frame(I(screen_name),degree,degree_in,degree_out,betweenness_centrality,eigenvector_centrality[[1]],pagerank,group)
cc <- c("screen_name", "degree","degree_in","degree_out","betweenness_centrality","eigenvector_centrality","pagerank","group")
colnames(datagrid) <- cc
rownames(datagrid) <- screen_name

# get a comma seperated list if user follows a sub group

# take a copy of the entire network edge list and add column names
edge = data.frame(connections)
colnames(edge) <- c('vert1','vert2')

# filter the edge list where source only follows subgroup then sort
edge = edge[edge$vert2 %in% subgroup, ]
edge = edge[order(edge$vert2) , ]

# last part is to work down the grid of screen names (lappy)
# find a subset of the edge dataframe where vert1 is the screen name 
# only selecting the results from vert2 e.g if mhawksey follows both 
# accounts a two row dataframe is returned. Results are collasped into
# a comma seperated value and assigned to a belongs_to column in the datagrid
datagrid$belongs_to = lapply(datagrid$screen_name, function(dfx) paste(as.character(subset(edge, vert1==dfx,select = 'vert2')$vert2), collapse=","))

# convert to JSON
dg = toJSON(data.frame(t(datagrid)))

#get top results from data.frame http://stackoverflow.com/a/3320420/1027723
datagrid.m <- subset( datagrid, select = -belongs_to )
datagrid.m <- melt(datagrid.m, id = 1)
a.screen_name <- cast(datagrid.m, screen_name ~ . | variable)
a.screen_name.max <- aaply(a.screen_name, 1, function(x) arrange(x, desc(`(all)`))[1:10,])
datagrid.screen_name.max <- adply(a.screen_name.max, 1)
toptens <- cbind(datagrid.screen_name.max[,2],datagrid.screen_name.max[,3],datagrid.screen_name.max[,1])
toptens = toJSON(toptens)
toptenslabels = toJSON(colnames(datagrid))

write.graph(g, paste(project,".graphml"), "graphml")

# write back to spreadsheet http://mashe.hawksey.info/2011/10/google-spreadsheets-as-a-database-insert-with-apps-script-form-postget-submit-method/
# SSL fix http://code.google.com/p/r-google-analytics/issues/detail?id=1#c3
options(RCurlOptions = list(capath = system.file("CurlSSL", "cacert.pem", package = "RCurl"), ssl.verifypeer = FALSE))
# post form
postForm(serviceUrl, "datagrid" = dg, "toptens" = toptens, "toptenslabels" = toptenslabels, "edges" = edges, "secret" = secret)
#write.table(datagrid,file=paste(project,"-datagrid.csv"),sep=",",row.names=F)
#write(dg,file=paste(project,"-dg.txt"))

# generate wordclouds based on groups
dataset = merge(datagrid,tab, by.x="screen_name",by.y="name")
keeps <- c("screen_name","group","description")
dataset = dataset[keeps]
groups = as.data.frame(table(dataset$group))
for(i in 1:nrow(groups)) {
  descSub = subset(dataset, group==groups[i,1])
  # this bit from http://onertipaday.blogspot.com/2011/07/word-cloud-in-r.html
  # note if you are pulling in multiple columns you may needd to change which one 
  # in the dataset is select e.g. dataset[,2] etc
  ap.corpus <- Corpus(DataframeSource(data.frame(as.character(descSub$description))))
  ap.corpus <- tm_map(ap.corpus, removePunctuation)
  ap.corpus <- tm_map(ap.corpus, tolower)
  ap.corpus <- tm_map(ap.corpus, function(x) removeWords(x, stopwords("english")))
  # additional stopwords can be used as shown below 
  #ap.corpus <- tm_map(ap.corpus, function(x) removeWords(x, c("ukoer","oer")))
  ap.tdm <- TermDocumentMatrix(ap.corpus)
  ap.m <- as.matrix(ap.tdm)
  ap.v <- sort(rowSums(ap.m),decreasing=TRUE)
  ap.d <- data.frame(word = names(ap.v),freq=ap.v)
  table(ap.d$freq)
  pal2 <- brewer.pal(8,"Dark2")
  svg(paste(project,"-wordcloud-group",groups[i,1],".svg", sep=""))
  # or png if you prefer 
  #png(paste(project,"-wordcloud-group",groups[i,1],".png", sep=""), width=1280,height=800)
  wordcloud(ap.d$word,ap.d$freq, scale=c(8,.2),min.freq=3,
            max.words=Inf, random.order=FALSE, rot.per=.15, colors=pal2)
  cc <- c("text", "size")
  colnames(ap.d) <- cc
  
  # write tables for each group with top 100 word freq
  write.table(ap.d[1:100,],file=paste(project,"wordcounts",groups[i,1],".csv"),sep=",",row.names=F)
  dev.off()
  # do stuff with row
}

# get data csv for template (repulish the spreadsheet to make sure the data is fresh)
tab2 = gsqAPI(key,queryB,gid)
write.table(tab2,file=paste(project,"data",".csv"),sep=",",row.names=F)
