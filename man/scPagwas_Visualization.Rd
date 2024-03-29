% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scPagwas_Visualization.R
\name{scPagwas_Visualization}
\alias{scPagwas_Visualization}
\title{scPagwas_Visualization}
\usage{
scPagwas_Visualization(
  scPagwas_score = NULL,
  Single_data = NULL,
  Reduction = FALSE,
  assay = "SCT",
  cellpercent = 0.1,
  filename = NULL,
  FigureType = "tsne",
  width = 7,
  height = 7,
  lowColor = "#000957",
  highColor = "#EBE645",
  size = 0.5,
  npcs = 50,
  title = "scPagwas_score",
  do_plot = F
)
}
\arguments{
\item{scPagwas_score}{scPagwas_score for scPagwas_main result}

\item{Single_data}{Single_data in seruat format ,the save with scPagwas_main(), you'd better to run reduction of UMAP AND TSNE}

\item{Reduction}{(logical) default is FALSE. Whether to run the Reduction for Single_data.If you are do it before,ignore it.}

\item{assay}{(character)"RNA" or "SCT", It depens on the Single_data.}

\item{cellpercent}{(numeric),default is 0.1, Threshold for pecent(<1) of Positive cells for level of scPagwas_score.}

\item{filename}{(character)default is NULL.the file folder name for save the figures.NULL means no folder is created, no pdf figure output.}

\item{FigureType}{(character)"tsne" or "umap}

\item{width}{(numeric)Figure width}

\item{height}{(numeric)Figure height}

\item{lowColor}{(character)Color for low scPagwas score}

\item{highColor}{(character)Color for high scPagwas score}

\item{size}{(numeric)size for scatters}

\item{npcs}{(integr) the parameter of Seurat::RunPCA.}

\item{title}{(character)Figure title}

\item{do_plot}{Whether to plot, logical}
}
\value{

}
\description{
Visualize the scPagwas score in Umap and Tsne.
}
\examples{
library(scPagwas)
data(scRNAexample)
#scPagwas_Visualization(
#  scPagwas = Pagwas,
#  Single_data = scRNAexample,
#  Reduction = FALSE,
#  assay = "SCT",
#  cellpercent = 0.1,
#  filename = "scpagwas_pbc_False",
#  FigureType = "tsne",
#  width = 7,
#  height = 7,
#  lowColor = "#000957", highColor = "#EBE645",
#  size = 0.5,
#  title = "scPagwas_score"
#)
}
