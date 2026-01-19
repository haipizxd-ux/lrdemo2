#' Generate example ligand-receptor data for demo/testing
#'
#' This function generates a small toy ligand-receptor network and two expression
#' matrices (sender and receiver) to demonstrate scoring and visualization.
#'
#' @param seed Integer. Random seed for reproducibility.
#' @return A list with \code{lr_network} (data.frame), \code{expr_sender} (matrix),
#'   and \code{expr_receiver} (matrix).
#' @export
make_example_data <- function(seed = 1) {
  set.seed(seed)
  
  lr_network <- data.frame(
    ligand   = c("Tgfb1", "Il6", "Ccl2", "Cxcl10", "Igf1", "Spp1"),
    receptor = c("Tgfbr2", "Il6ra", "Ccr2", "Cxcr3", "Igf1r", "Cd44"),
    stringsAsFactors = FALSE
  )
  
  sender_cells   <- c("Microglia", "Astrocyte")
  receiver_cells <- c("Neuron", "Endothelial", "OPC")
  
  genes <- unique(c(lr_network$ligand, lr_network$receptor,
                    "Apoe", "Trem2", "Gfap", "Pdgfra", "Pecam1"))
  
  expr_sender <- matrix(rexp(length(genes) * length(sender_cells), rate = 1.2),
                        nrow = length(genes), dimnames = list(genes, sender_cells))
  expr_receiver <- matrix(rexp(length(genes) * length(receiver_cells), rate = 1.2),
                          nrow = length(genes), dimnames = list(genes, receiver_cells))
  
  # Structured signals (so output is visually meaningful)
  expr_sender["Il6",    "Microglia"]  <- expr_sender["Il6", "Microglia"] + 2.5
  expr_sender["Tgfb1",  "Astrocyte"]  <- expr_sender["Tgfb1", "Astrocyte"] + 2.0
  expr_sender["Ccl2",   "Microglia"]  <- expr_sender["Ccl2", "Microglia"] + 1.8
  expr_sender["Spp1",   "Microglia"]  <- expr_sender["Spp1", "Microglia"] + 2.2
  
  expr_receiver["Il6ra",  "Endothelial"] <- expr_receiver["Il6ra", "Endothelial"] + 2.2
  expr_receiver["Tgfbr2", "Neuron"]      <- expr_receiver["Tgfbr2", "Neuron"] + 1.8
  expr_receiver["Ccr2",   "Endothelial"] <- expr_receiver["Ccr2", "Endothelial"] + 1.5
  expr_receiver["Cd44",   "OPC"]         <- expr_receiver["Cd44", "OPC"] + 2.0
  expr_receiver["Igf1r",  "Neuron"]      <- expr_receiver["Igf1r", "Neuron"] + 1.2
  
  list(
    lr_network = lr_network,
    expr_sender = expr_sender,
    expr_receiver = expr_receiver
  )
}

#' Score active ligand-receptor pairs across sender/receiver cell types
#'
#' Given expression matrices and a ligand-receptor network, this function filters
#' active pairs by expression cutoffs and computes a simple interaction score.
#'
#' @param expr_sender Numeric matrix. Rows are genes, columns are sender cell types.
#' @param expr_receiver Numeric matrix. Rows are genes, columns are receiver cell types.
#' @param lr_network Data frame with columns \code{ligand} and \code{receptor}.
#' @param sender_cutoff Numeric. Minimum ligand expression to be considered active.
#' @param receiver_cutoff Numeric. Minimum receptor expression to be considered active.
#' @param score Scoring method: \code{"product"} or \code{"geometric_mean"}.
#' @return A data.frame with columns: sender, receiver, ligand, receptor,
#'   ligand_expr, receptor_expr, lr_score, pair, cellpair.
#' @export
score_active_lr <- function(expr_sender, expr_receiver, lr_network,
                            sender_cutoff = 1.0, receiver_cutoff = 1.0,
                            score = c("product", "geometric_mean")) {
  score <- match.arg(score)
  
  senders <- colnames(expr_sender)
  receivers <- colnames(expr_receiver)
  
  keep <- lr_network$ligand %in% rownames(expr_sender) &
    lr_network$receptor %in% rownames(expr_receiver)
  lr <- lr_network[keep, , drop = FALSE]
  
  if (nrow(lr) == 0) {
    stop("No ligand/receptor genes found in the provided expression matrices.")
  }
  
  out <- list()
  
  for (s in senders) {
    lig_expr <- expr_sender[lr$ligand, s]
    names(lig_expr) <- lr$ligand
    
    for (r in receivers) {
      rec_expr <- expr_receiver[lr$receptor, r]
      names(rec_expr) <- lr$receptor
      
      active <- (lig_expr >= sender_cutoff) & (rec_expr >= receiver_cutoff)
      if (!any(active)) next
      
      L <- lig_expr[active]
      R <- rec_expr[active]
      
      sc <- if (score == "product") {
        as.numeric(L) * as.numeric(R)
      } else {
        sqrt(as.numeric(L) * as.numeric(R))
      }
      
      df <- data.frame(
        sender = s,
        receiver = r,
        ligand = lr$ligand[active],
        receptor = lr$receptor[active],
        ligand_expr = as.numeric(L),
        receptor_expr = as.numeric(R),
        lr_score = sc,
        stringsAsFactors = FALSE
      )
      
      out[[length(out) + 1]] <- df
    }
  }
  
  if (length(out) == 0) {
    return(data.frame(
      sender = character(), receiver = character(),
      ligand = character(), receptor = character(),
      ligand_expr = numeric(), receptor_expr = numeric(),
      lr_score = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  
  res <- do.call(rbind, out)
  res$pair <- paste0(res$ligand, " \u2192 ", res$receptor)
  res$cellpair <- paste0(res$sender, " \u2192 ", res$receiver)
  
  res <- res[order(res$cellpair, -res$lr_score), ]
  rownames(res) <- NULL
  res
}

#' Plot ligand-receptor scoring results
#'
#' Creates a tile heatmap (cellpair vs LR pair) and a bar plot of top pairs
#' aggregated by score.
#'
#' @param scored_df Output from \code{score_active_lr()}.
#' @param top_n_pairs Integer. Number of top LR pairs to show in the bar plot.
#' @return Invisibly returns a list with \code{heatmap} and \code{top_pairs} ggplot objects.
#' @export
plot_lr_results <- function(scored_df, top_n_pairs = 8) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }
  ggplot2 <- asNamespace("ggplot2")
  
  if (nrow(scored_df) == 0) {
    message("No active ligand-receptor pairs under the current cutoffs.")
    return(invisible(NULL))
  }
  
  p1 <- ggplot2$ggplot(scored_df, ggplot2$aes(x = pair, y = cellpair, fill = lr_score)) +
    ggplot2$geom_tile(color = "white", linewidth = 0.3) +
    ggplot2$labs(
      title = "Active ligand-receptor scores (tile heatmap)",
      x = "Ligand \u2192 Receptor",
      y = "Sender \u2192 Receiver",
      fill = "Score"
    ) +
    ggplot2$theme_minimal(base_size = 12) +
    ggplot2$theme(
      axis.text.x = ggplot2$element_text(angle = 45, hjust = 1, vjust = 1),
      panel.grid = ggplot2$element_blank()
    )
  
  agg <- stats::aggregate(lr_score ~ pair, data = scored_df, FUN = sum)
  agg <- agg[order(-agg$lr_score), , drop = FALSE]
  agg <- head(agg, top_n_pairs)
  agg$pair <- factor(agg$pair, levels = rev(agg$pair))
  
  p2 <- ggplot2$ggplot(agg, ggplot2$aes(x = pair, y = lr_score)) +
    ggplot2$geom_col() +
    ggplot2$coord_flip() +
    ggplot2$labs(
      title = paste0("Top ", top_n_pairs, " ligand-receptor pairs (sum of scores)"),
      x = NULL,
      y = "Sum score"
    ) +
    ggplot2$theme_minimal(base_size = 12)
  
  print(p1)
  print(p2)
  
  invisible(list(heatmap = p1, top_pairs = p2))
}
