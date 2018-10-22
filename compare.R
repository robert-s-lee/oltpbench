
proc <- read.csv(file="~/github/oltpbench/results/proc.csv", header=FALSE, sep=",")

names(proc) <- c("procedure","totaltime","count","database","benchmark","run","terminal","sf","server","rate","file" );

proc$avg <- proc$totaltime / proc$count

proc1 <- subset(proc, benchmark=="tpcc" & server=="hplan")

b <- "auctionmark"
b <- "linkbench"
b <- "seats"
b <- "tpcc"
b <- "tatp"
b <- "twitter"
b <- "voter"
b <- "epinions"
b <- "sibench"
b <- "smallbank"
b <- "ycsb"
b <- "wikipedia"
b <- "resourcestresser"

benchmarks <- c("auctionmark" ,"linkbench" ,"seats" ,"tpcc" ,"tatp" ,"twitter" ,"voter" ,"epinions" ,"sibench" ,"smallbank" ,"ycsb" ,"wikipedia" ,"resourcestresser" )

for (b in benchmarks) {

print(
ggplot(subset(proc, benchmark==b & server=="hplan" & count > 1),aes(procedure,avg))+geom_point()+facet_grid(database ~ terminal) + theme(axis.text.x = element_text(angle = 90, hjust = 1)) + labs(title= paste(b,"response time in nanosecons"))
)
readline(prompt="Press [enter] to continue")

}

