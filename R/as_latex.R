#' Output a gt object as LaTeX
#'
#' Take a \code{gt_tbl} table object and emit LaTeX.
#' @param data a table object that is created using the \code{gt()} function.
#' @import rlang
#' @importFrom dplyr mutate group_by summarize ungroup rename arrange
#' @importFrom stats setNames
#' @examples
#' # Use `gtcars` to create a gt table;
#' # add a header and then export as
#' # LaTeX code (use `as.character()`
#' # to get just the code and no LaTeX
#' # dependencies for R Markdown)
#' tab_1 <-
#'   gtcars %>%
#'   dplyr::select(mfr, model, msrp) %>%
#'   dplyr::slice(1:5) %>%
#'   gt() %>%
#'   tab_header(
#'     title = md("Data listing from **gtcars**"),
#'     subtitle = md("`gtcars` is an R dataset")
#'   ) %>%
#'   as_latex()
#' @family table export functions
#' @export
as_latex <- function(data) {

  # Build all table data objects through a common pipeline
  built_data <- data %>% build_data(context = "latex")

  # Use LaTeX-specific builders to generate the Latex table code
  with(built_data, {

    # Add footnote glyphs to elements of the table columns
    boxh_df <-
      set_footnote_glyphs_columns(footnotes_resolved, boxh_df, output = "latex")

    # Add footnote glyphs to the `data` rows
    output_df <-
      apply_footnotes_to_output(output_df, footnotes_resolved, output = "latex")

    # Add footnote glyphs to stub group title elements
    groups_rows_df <-
      set_footnote_glyphs_stub_groups(
        footnotes_resolved, groups_rows_df, output = "latex")

    # Add footnote glyphs to the `summary` rows
    list_of_summaries <-
      apply_footnotes_to_summary(list_of_summaries, footnotes_resolved)

    # Extraction of body content as a vector ----------------------------------
    body_content <- as.vector(t(output_df))

    # Composition of LaTeX ----------------------------------------------------

    # Split `body_content` by slices of rows
    row_splits <- split(body_content, ceiling(seq_along(body_content) / n_cols))

    # Create a LaTeX fragment for the start of the table
    table_start <- create_table_start_l(col_alignment)

    # Create the heading component of the table
    heading_component <-
      create_heading_component(
        heading, footnotes_resolved, n_cols = n_cols, output = "latex")

    # Create the columns component of the table
    columns_component <-
      create_columns_component_l(
        boxh_df, output_df, stub_available, spanners_present,
        stubhead_label)

    # Create the body component of the table
    body_component <-
      create_body_component_l(
        row_splits, groups_rows_df, col_alignment, stub_available,
        summaries_present, list_of_summaries, n_rows, n_cols)

    # Create a LaTeX fragment for the ending tabular statement
    table_end <- create_table_end_l()

    # Create the footnote component of the table
    footnote_component <-
      create_footnote_component_l(
        footnotes_resolved, opts_df)

    # Create the source note component of the table
    source_note_component <-
      create_source_note_component_l(source_note)

    # If the `rmarkdown` package is available, use the
    # `latex_dependency()` function to load latex packages
    # without requiring the user to do so
    if (requireNamespace("rmarkdown", quietly = TRUE)) {
      latex_packages <-
        list(
          rmarkdown::latex_dependency("longtable"),
          rmarkdown::latex_dependency("booktabs"),
          rmarkdown::latex_dependency("caption"))
    } else {
      latex_packages <- NULL
    }

    # Compose the LaTeX table
    latex_table <-
      paste0(
        table_start,
        heading_component,
        columns_component,
        body_component,
        table_end,
        footnote_component,
        source_note_component,
        collapse = "") %>%
      knitr::asis_output(meta = latex_packages)

    latex_table
  })
}
