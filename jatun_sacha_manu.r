### Read external commands
library(shipunov)

### Read input tables
## "as.is=TRUE" is to avoid conversion into factors
## Main table (species list), serves also as feature (images) table:
pics <- read.table("_sp_pics.txt", sep="\t", as.is=TRUE)
## Other feature tables:
auth <- read.table("_sp_auth.txt", sep="\t", as.is=TRUE, quote="") # need "quote" because some author names might contain quote-like symbols
fam <- read.table("_gen_fam.txt", sep="\t", as.is=TRUE)
txt <-  read.table("_sp_text.txt", sep="\t", as.is=TRUE)
## Filter tables
alt <- read.table("_fam_alt.txt", sep="\t", as.is=TRUE)

### Make species names and start the main output table
SPEC <- pics[, 1]
AUTH <- Recode4(SPEC, auth[, 1], auth[, 2])
write(SPEC[AUTH == ""], file="0no_sp_auth.txt") # diagnostics!
AUTH <- gsub("&", "\\\\&", AUTH) # because ampersand is the special symbol in TeX
JS <- data.frame(SPEC=paste0("\\SP{", paste0("\\KK{", SPEC, "}"), " ", AUTH, "}"))

### Make links to images
## There could be > 1 image per species so:
IMG0 <- aggregate(pics[, 2], list(pics[, 1]), function(.x) paste0("\\I{", .x, "}", collapse=" "))
IMG1 <- Recode4(SPEC, IMG0[, 1], IMG0[, 2])
write(SPEC[IMG1 == ""], file="0no_pics.txt") # diagnostics!
JS$IMG <- paste0("\\II{", IMG1, "}")

### Make text descriptions
TXT <- Recode4(SPEC, txt[, 1], txt[, 2])
for (i in 1:length(TXT)) if (TXT[i] != "") TXT[i] <- paste0(readLines(con=paste0("texts/", TXT[i])), collapse=" ")
write(SPEC[TXT == ""], file="0no_sp_text.txt") # diagnostics!
JS$TXT <- ifelse(TXT != "", paste0("\\DD{", TXT, "}"), "")

### Make genera
GEN <- do.call(rbind, strsplit(SPEC, " "))[, 1] # outputs matrix, we need the first column with genus name
### Make names of higher categories (here families) and immediately convert it from alternative to traditional
JS$FAM <- Recode(Recode4(GEN, fam[, 1], fam[, 2]), alt[, 1], alt[, 2])
write(SPEC[JS$FAM == ""], file="0no_fam.txt") # diagnostics!
JS <- JS[order(JS$FAM, JS$SPEC), ]
## We need these names only on the first occurrence:
JS$FAM <- ifelse(!duplicated(JS$FAM), paste0("\\FF{", "Family ", "\\KK{", JS$FAM, "}}"), "")

### Write the output table
write.table(file="0body", JS[, c("FAM", "SPEC", "IMG", "TXT")], quote=FALSE,
 row.names=FALSE, col.names=FALSE, sep=" ", eol="\n\n")
