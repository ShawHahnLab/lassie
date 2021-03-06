#' @keywords internal
concatamerize <- function(aln_allcolumns, selected_sites) {
# despite the name this merely extracts columns of selected sites,
# forming a smaller matrix, not a vector or list of concatamer sequences

    # error check bounds on input
    if (any(selected_sites > ncol(aln_allcolumns)))
	stop("ERROR in concatamerize(): selected sites extend beyond input alignment")

    aln_allcolumns[, selected_sites]
}
