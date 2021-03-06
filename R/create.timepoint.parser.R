#' Generate a closure function to parse timepoint labels from sequence names.
#'
#' @param field.sep Character used to separate fields in sequence names.
#' @param field.num Field in sequence names that contains timepoint labels.
#' @return Validated function to return the specific, delimited field from each sequence name.
#' @examples
#' tp <- create.timepoint.parser(field.sep=".", field.num=1)
#' tp <- create.timepoint.parser(field.sep="_", field.num=2)
#' @export
create.timepoint.parser <- function(field.sep, field.num) {

    if (is.null(field.sep) | is.null(field.num))
        stop("USAGE: create.timepoint.parser(field.sep=int, field.num=char)\nThis function returns a function to parse timepoints from sequence names.\n")

    # assert that arguments are valid
    if (length(field.sep) > 1)
        stop(paste(
            "ERROR in create.timepoint.parser(): field.sep must be a scalar;\n",
            paste(field.sep, collapse='\n'), "is not valid."))

    if (!is.character(field.sep))
        stop(paste(
            "ERROR in create.timepoint.parser(): field.sep must be a character;",
            field.sep, "is not valid."))

    if (nchar(field.sep) > 1)
        stop(paste(
          "ERROR in create.timepoint.parser(): field.sep must be a single character;",
            field.sep, "is not valid."))

    if (length(field.num) > 1) 
        stop(paste(
            "ERROR in create.timepoint.parser(): field.num must be a scalar;\n",
            paste(field.num, collapse='\n'), "is not valid."))

    if (!is.integer(as.integer(field.num)))
        stop(paste(
            "ERROR in create.timepoint.parser(): field.num must be an integer;",
            field.num, "is not valid."))

    field.num <- as.integer(field.num)

    if (field.num < 1) 
        stop(paste(
          "ERROR in create.timepoint.parser(): field.num must be a cardinal number;",
            field.num, "is not valid."))

    # this is a closure function
## TO DO: CONSIDER HOW TO IGNORE THE REFSEQ NAME WITHOUT FAILING IF PRESENT 

## 01072016 - do.tests is always true.
# for non-interactive use, need to exit / fail / return gracefully

    function(in.vec=NULL, do.tests=F) {

        if (is.null(in.vec))
            return ( NULL )

        if (do.tests) {

            # could test for errors here
            if (any(!grepl(field.sep, in.vec, fixed=T))) {
                message(paste0("ERROR parsing timepoints: are sequence names delimited by this character '",
                    field.sep, "'?\nThese names are missing it:\n",
                    paste(in.vec[which(!grepl(field.sep, in.vec, fixed=T))], 
                        collapse='\n')))

#                return ( NULL )
            }
            # this contains a list of the field separators, for counting
            testing.matches <- regmatches(in.vec, 
                tmp.matches <- gregexpr(field.sep, in.vec, fixed=T))

            # now review for imminent parse failures
            n.fields <- sapply(1:length(testing.matches), function(i)
                1 + length(testing.matches[[i]]))

            if (any(n.fields < field.num))
                message(paste(
                "ERROR parsing timepoints: too few fields in some names:\n", 
                        paste(in.vec[which(n.fields < field.num)], 
                            collapse='\n')))
        }
        # if input passes those tests, it should parse just fine, right?

        out.vec <- rep(NA, length(in.vec))

        for (i in 1:length(in.vec))
            if (length(unlist(strsplit(in.vec[i], field.sep, fixed=T))) 
		    >= field.num)
                out.vec[i] = unlist(strsplit(in.vec[i], field.sep, 
                    fixed=T))[[field.num]]

        out.vec
    }
}
