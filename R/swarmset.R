#' Select sequences to represent mutations in selected sites.
#' 
#' Analyze longitudinal protein sequences for variants among selected sites.
#'
#' @param ST swarmtools object, with list of selected sites.
#' @param maxtol_deletion Maximum tolerated deletion length.
#' @param maxtol_insertion Maximum tolerated insertion.
#' @param included_clone_names List of included clone names.
#' @param excluded_clone_names List of excluded clone names.
#' @param min_counts Variants that occur less often than this number in the 
#' entire alignment are not included in swarms.  The default value (2) catches 
#' all recurrent mutations.
#'
#' @return A swarmset object with selected sequences in a slot called 
#' \code{working_swarm} with values \code{is_included==T}, 
#' i.e. \code{names(which(B$working_swarm$is_included))}.
#'
#' @examples
#' \dontrun{
#'   A <- lassie::swarmtools(aas_file=system.file("extdata", "CH505-gp160.fasta", 
#'             package="lassie"), tf_loss_cutoff=80)
#'   B <- lassie::swarmset(A)
#' }
#'
#' @seealso \code{\link{swarmtools}}
#'
#' @family swarmset methods
#'
#' @export
swarmset <- function(ST,
    maxtol_deletion=NULL, # maximum tolerated, i.e. longest allowed
    maxtol_insertion=NULL,
    included_clone_names=NULL,
    excluded_clone_names=NULL,
    min_counts=2 # variants with fewer than min_counts present are used to 
                 # compute TF loss but not included in swarms
    ) {

    if (class(ST) != "swarmtools")
	stop("swarmset ERROR: please provide a swarmtools object")

# By keeping "this" here, rather than moving it into select.clones, it
# is no longer necessary to pass around ST$selected_sites or the
# swarmtools object until summarizing results

    message = NULL

    if (is.null(ST)) { # attempt to continue without errors if swarmtools object not fully populated, for interactive (shiny gui) use
       ST$aas_aln = NULL
       ST$original_seqnames = NULL
    }

    is_included = init.clone.list(ST$aas_aln)
# this list is maintained separately from that above to add entries 
# only when iterating for the timepoint of the also_included clones
# (as provided from user land via included_clone_names);
# set it here to keep ST out of select.clones()
    is_also_included = init.clone.list(ST$aas_aln)
    is_excluded = init.clone.list(ST$aas_aln)

    if (!is.null(included_clone_names)) {

	if (any(!included_clone_names %in% ST$original_seqnames))
	    stop(paste(
     "ERROR in swarmset()! Unidentified clone/s named for inclusion: ",
	        which(!included_clone_names %in% ST$original_seqnames)))

	is_also_included[which(ST$original_seqnames %in% 
		included_clone_names)] = T
    }

    if (!is.null(excluded_clone_names)) {

	if (any(!excluded_clone_names %in% ST$original_seqnames))
	    stop(paste(
     "ERROR in swarmset()! Unidentified clone/s named for exclusion: ",
	        which(!excluded_clone_names %in% ST$original_seqnames)))

	is_excluded[which(ST$original_seqnames %in% excluded_clone_names)] = T
    }

    # are 20% of alignment lengths for these reasonable defaults?  warn user?
    # to do: notify user to confirm excluded sequence
    if (is.null(maxtol_deletion))
	maxtol_deletion <- ncol(ST$aas_aln)/5

    longest_deletion <- longest.deletion.per.sequence(ST$aas_aln)

    if (any(longest_deletion > maxtol_deletion))
	is_excluded[which(longest_deletion > maxtol_deletion)] = T

    if (is.null(maxtol_insertion))
	maxtol_insertion <- ncol(ST$aas_aln)/5

    longest_insertion <- longest.insertion.per.sequence(ST$aas_aln)

    if (any(longest_insertion > maxtol_insertion)) {

	is_excluded[which(longest_insertion > maxtol_insertion)] = T

	message(paste0("Excluding ", 
		    length(which(longest_insertion > maxtol_insertion)),
		    " sequences with insertions over ", maxtol_insertion, 
		    " aas"))
	message = append(message, 
	    paste0("Excluding ", 
		length(which(longest_insertion > maxtol_insertion)),
		" sequences with insertions over ", maxtol_insertion, 
		" aas"))
    }

    if (any(is_included))
	message(paste("Including", 
	    paste(names(which(is_included)), collapse=",")))

    if (any(is_included))
	message = append(message, 
	    paste("Including", 
	    paste(names(which(is_included)), collapse=",")))

    if (any(is_excluded))
	message(paste("Excluding", 
	    paste(names(which(is_excluded)), collapse=",")))

    if (any(is_excluded))
	message = append(message, 
	    paste("Excluding", paste(names(which(is_excluded)), collapse=",")))

    aln_concatamer <- concatamerize(ST$aas_aln, ST$selected_sites$aln)

    working_swarm <- select.clones(ST$aas_aln, ST$tf_index, 
	aln_concatamer, is_included, is_also_included, 
	is_excluded, min_counts, 
	ST$sequence_multiplicity, ST$timepoints_parser, 
	message)

    retval <- list(
	working_swarm=working_swarm,
#	ptid = ST$ptid, # add more?  region?  prefix?
	tf_index = ST$tf_index,
	tf_name = ST$tf_name,
	aln_allcolumns=ST$aas_aln,
	aln_concatamer=aln_concatamer,
	results_prefix=paste0(ST$aas_prefix, '-', ST$tf_loss_cutoff_s),
	selected_sites=ST$selected_sites,
    maxtol_deletion=maxtol_deletion, # maximum tolerated, i.e. longest allowed
    maxtol_insertion=maxtol_insertion,
    is_also_included=is_also_included,
    included_clone_names=included_clone_names,
    excluded_clone_names=excluded_clone_names,
    min_counts=min_counts # variants with fewer than min_counts present are 
                          # used to compute TF loss but not included in swarms
    )

    class(retval) <- "swarmset"

    retval
}
