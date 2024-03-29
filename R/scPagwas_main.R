
#' @importFrom dplyr mutate filter inner_join %>%
#' @importFrom irlba irlba
#' @importFrom Seurat FindVariableFeatures AverageExpression VariableFeatures GetAssayData RunPCA RunTSNE RunUMAP Embeddings
#' @importFrom SeuratObject Idents
#' @importFrom Matrix Matrix colSums rowSums crossprod
#' @importFrom stringr str_replace_all
#' @importFrom parallel mclapply
#' @importFrom glmnet cv.glmnet
#' @importFrom GenomicRanges GRanges resize resize
#' @importFrom IRanges IRanges
#' @importFrom utils timestamp
#' @import ggplot2
#' @importFrom ggpubr ggscatter
#' @importFrom bigstatsr as_FBM big_apply big_univLinReg covar_from_df big_transpose big_cprodMat
#' @importFrom RMTstat qWishartMax
#' @importFrom gridExtra grid.arrange
#' @importFrom data.table setkey data.table as.data.table
#' @importFrom bigreadr fread2 rbind_df
#' @importFrom reshape2 dcast
#' @importFrom bigmemory as.big.matrix is.big.matrix
#' @importFrom biganalytics apply

#' @title Main wrapper functions for scPagwas
#' @name scPagwas_main
#' @description Main Pagwas wrapper re-progress function.
#' @details The entry point for Pagwas analysis.
#'
#' @param Pagwas (list)Pagwas data list, default is "NULL"
#' @param gwas_data (data.frame)GWAS summary data
#' @param add_eqtls (character)There are three options: "OnlyTSS","OnlyEqtls","Both"; "OnlyTSS" means there is only snps within TSS window;"OnlyEqtls" represents only significant snps in eqtls files;  "Both" represents both significant snps in eqtls and the other snps in GWAS summary files;
#' @param marg (integr)gene-TSS-window size
#' @param eqtls_files (character)eqtls files names,frome GTEx.
#' @param eqtls_cols (character) the needed columns in eqtls_files; In our examples files, the columns including: c("rs_id_dbSNP151_GRCh38p7","variant_pos","tss_distance","gene_chr", "gene_start", "gene_end","gene_name")
#' @param block_annotation (data.frame) Start and end points for block traits, usually genes.
#' @param Single_data (Seruat)Input the Single data in seruat format, Idents should be the celltypes annotation.
#' @param assay (character)assay data of your single cell data to use,default is "RNA"
#' @param nfeatures (integr) The parameter for FindVariableFeatures, NULL means select all genes
#' @param Pathway_list (list,character) pathway gene sets list
#' @param chrom_ld (list,numeric)LD data for 22 chromosome.
#' @param maf_filter (numeric)Filter the maf, default is 0.01
#' @param min_clustercells (integr)Only use is when FilterSingleCell is TRUE.Threshold for total cells fo each cluster.default is 10
#' @param min.pathway.size (integr)Threshold for min pathway gene size. default is 5
#' @param max.pathway.size (integr)Threshold for max pathway gene size. default is 300
#' @param n.cores (integr)Parallel cores,default is 1. use detectCores() to check the cores in computer.
#'
#' @return
#' @export
#'
#' @examples
#' library(scPagwas)
#' data(Genes_by_pathway_kegg)
#' data(GWAS_summ_example)
#' data(gtf_df)
#' data(scRNAexample)
#' #data(eqtls_files)
#' data(chrom_ld)
#' #1. OnlyTSS
#' Pagwas<-scPagwas_main(Pagwas = NULL,
#'                     gwas_data = GWAS_summ_example,
#'                     add_eqtls="OnlyTSS",
#'                     block_annotation = gtf_df,
#'                     Single_data = scRNAexample,
#'                     Pathway_list=Genes_by_pathway_kegg,
#'                     chrom_ld = chrom_ld)
#'
scPagwas_main <- function(Pagwas = NULL,
                        gwas_data = NULL,
                        add_eqtls="OnlyTSS",
                        eqtls_files=NULL,
                        eqtls_cols=c("rs_id_dbSNP151_GRCh38p7","variant_pos","tss_distance","gene_chr", "gene_start", "gene_end","gene_name","pval_beta"),
                        block_annotation = NULL,
                        Single_data = NULL,
                        assay="RNA",
                        nfeatures =NULL,
                        Pathway_list=NULL,
                        chrom_ld=NULL,
                        marg=10000,
                        maf_filter = 0.01,
                        min_clustercells=10,
                        min.pathway.size=5,
                        max.pathway.size=300,
                        n.cores=1) {
  if (is.null(Pagwas)) {
  Pagwas <- list();
  class(Pagwas) <- 'Pagwas'
  }
   message(paste(utils::timestamp(quiet = T), ' ******* 1st: Single_data_input function start! ********',sep = ''))

  #suppressMessages(require(SeuratObject))
  #if(class(Single_data)=="character"){
  if(grepl(".rds",Single_data)){
    message("** Start to read the single cell data!")
    Single_data=readRDS(Single_data)
  }else{
    stop("There is need a data in `.rds` format ")
  }

  if(!assay %in% Assays(Single_data)){
    stop("There is no need assays in your Single_data")
  }
    Pagwas <- Single_data_input(Pagwas=Pagwas,
                                assay=assay,
                                nfeatures =nfeatures,
                                Single_data=Single_data,
                                Pathway_list=Pathway_list,
                                min_clustercells=min_clustercells)
  rm(Single_data)

  #message(ncol(Pagwas$Single_data)," cells are remain!" )
  message('done!')

  #3.calculated pca score
  message(paste(utils::timestamp(quiet = T), ' ******* 2nd: Pathway_pcascore_run function start!! ********',sep = ''))


  if (!is.null(Pathway_list)){


  Pagwas <- Pathway_pcascore_run(Pagwas=Pagwas,n.cores=n.cores,
                                 Pathway_list=Pathway_list,
                                 min.pathway.size=min.pathway.size,
                                 max.pathway.size=max.pathway.size
                                 )

   }
   message('done!')


   message(paste(utils::timestamp(quiet = T), ' ******* 3rd: GWAS_summary_input function start! ********',sep = ''))

   if(class(gwas_data)=="character"){
     message("** Start to read the gwas_data!")

     suppressMessages(gwas_data <- bigreadr::fread2(gwas_data))

   }else{
     stop("There is need a filename and address for gwas_data")
   }

     Pagwas <- GWAS_summary_input(Pagwas=Pagwas,
                                  gwas_data=gwas_data,
                                  maf_filter=maf_filter)
   rm(gwas_data)
   message('done!')

   #4.calculated Snp2Gene
  message(paste(utils::timestamp(quiet = T), ' ******* 4th: Snp2Gene start!! ********',sep = ''))

  if(!is.null(block_annotation)){

    if(add_eqtls!="OnlyTSS"){
      if (!is.null(eqtls_files)){

        message("Filter snps for significant eqtls!")
        Pagwas<-  Tissue_eqtls_Input(Pagwas=Pagwas,
                                     block_annotation=block_annotation,
                                     add_eqtls=add_eqtls,
                                     eqtls_files=eqtls_files,
                                     eqtl_p=0.05,
                                     eqtls_cols=eqtls_cols,
                                     marg=marg)

       }else{

        stop("Since the add_eqtls is TURE! No parameter 'eqtls_files' Input!  ")
       }
    }else{

       snp_gene_df<-Snp2Gene(snp=Pagwas$gwas_data,refGene=block_annotation,marg=marg)
       snp_gene_df$slope <- rep(1,nrow(snp_gene_df))
       Pagwas$snp_gene_df<-snp_gene_df[snp_gene_df$Disstance=="0",]
    }
  }
  #3.pathway block data
  message(paste(utils::timestamp(quiet = T), ' ******* 5th: Pathway_annotation_input function start! ********',sep = ''))

  if (!is.null(block_annotation)){
    Pagwas <- Pathway_annotation_input(Pagwas=Pagwas,
                                       block_annotation=block_annotation,
                                       n.cores=n.cores)
  }

  message('done!')

  #4.ld data folder,which is preprogress

  message(paste(utils::timestamp(quiet = T), ' ******* 6th: Link_pathway_blocks_gwas function start! ********',sep = ''))

  if (!is.null(chrom_ld)){

    Pagwas <- Link_pathway_blocks_gwas(Pagwas=Pagwas,
                                       chrom_ld=chrom_ld,
                                       n.cores=n.cores)

   message('done!')
  }

  gc()
  return(Pagwas)
}
