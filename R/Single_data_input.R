

#' Single_data_input
#' @description Input the Single data in seruat format
#'
#' @param Pagwas Pagwas format
#' @param Single_data Input the Single data in seruat format, Idents should be
#' the celltypes annotation. mainly used the Single_data@assays$RNA@data
#' @param Pathway_list (list,character) pathway gene sets list
#' @param nfeatures The parameter for FindVariableFeatures,
#' NULL means select all genes
#' @param min_clustercells Threshold for total cells fo each cluster.
#'
#' @return Pagwas
#' @export
#'
#' @examples
#' library(scPagwas)
#' data(scRNAexample)
#' # Pagwas is better getting from GWAS_summary_input(),or NULL is right,
#' Pagwas <- Single_data_input(Pagwas = Pagwas, Single_data = scRNAexample)
Single_data_input <- function(Pagwas,
                              Single_data,
                              nfeatures = NULL,
                              Pathway_list=NULL,
                              assay="RNA",
                              min_clustercells = 5) {
  message("Input single cell data!")

  if (!("Seurat" %in% class(Single_data))) {
    message("Single_data is not of class Seurat!")
    return(Pagwas)
  }
  #1.Celltype_anno
  Celltype_anno <- data.frame(cellnames = rownames(Single_data@meta.data),
                              annotation = as.vector(SeuratObject::Idents(Single_data)))
  rownames(Celltype_anno) <- Celltype_anno$cellnames
  #2.filter cell_types
  Afterre_cell_types <- table(Celltype_anno$annotation) > min_clustercells
  Afterre_cell_types <- names(Afterre_cell_types)[Afterre_cell_types]
  message(length(Afterre_cell_types), " cell types are remain, after filter!")
  #message(1)
  Celltype_anno <- Celltype_anno[Celltype_anno$annotation %in% Afterre_cell_types, ]
  Single_data <-Single_data[,Celltype_anno$cellnames]
  #message(2)
  Pagwas$Celltype_anno<-Celltype_anno
  #3.raw_data_mat
  #options(bigmemory.allow.dimnames=TRUE)

  #a <- GetAssayData(Single_data, slot = "data", assay =assay)
  #Pagwas$raw_data_mat <- bigmemory::big.matrix(nrow(a),ncol(a),shared = FALSE)
  Pagwas$data_mat<- GetAssayData(Single_data, slot = "data", assay =assay)
  #rownames(Pagwas$raw_data_mat) <- rownames(a)
  #rm(a)
  #message(3)
  #4.merge_scexpr
  merge_scexpr <- Seurat::AverageExpression(Single_data,assays=assay)[[assay]]

  #message(4)
  #5.VariableFeatures
  if (!is.null(nfeatures)) {
    if (nfeatures < nrow(Pagwas$data_mat)) {
      Single_data <- Seurat::FindVariableFeatures(Single_data,
                                                    assay =assay,
                                                    selection.method = "vst",
                                                    nfeatures = nfeatures
                                                    )
      Pagwas$VariableFeatures <- Seurat::VariableFeatures(Single_data)
      # Single_data <- Single_data[,]
    } else if (nfeatures == nrow(Pagwas$data_mat)) {
      Pagwas$VariableFeatures <- rownames(Pagwas$data_mat)
    } else {
      stop("Error: nfeatures is too big")
    }
  } else {
    Pagwas$VariableFeatures <- rownames(Pagwas$data_mat)
  }
  rm(Single_data)
  #6.get data_mat
  #message(5)
  pagene<- intersect(unique(unlist(Pathway_list)),rownames(Pagwas$data_mat))
  if(length(pagene)<100){
    stop("There are little match between rownames of Single_data and pathway genes!")
  }

  Pagwas$VariableFeatures <- intersect(Pagwas$VariableFeatures,pagene)
  #a<-data.matrix(Seurat::GetAssayData(object = Single_data[pagene,], slot = "data"))
  #message(6)
  #Pagwas$data_mat <- Pagwas$raw_data_mat[Pagwas$VariableFeatures,]
  #message(7)
  Pagwas$merge_scexpr <-merge_scexpr[Pagwas$VariableFeatures,]
  return(Pagwas)
}
