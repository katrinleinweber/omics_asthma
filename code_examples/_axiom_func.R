#Functions for the Leaf_print project
#Tom Poorten, Mitchell Feldmann, Randi Famula
#github.com/tpoorten/leaf_print

################################################
#The purpose of this function is to read and compile all sample, SNP, and metadata.
leaf_read = function(snp_data_file=NULL, ps_qc_file = NULL, sample_qc_file=NULL, sample_meta_file=NULL){
  if(file.exists(snp_data_file)){
    snp_data = read.table(snp_data_file, sep="\t", header=T, stringsAsFactors = F, check.names = F)
    rownames(snp_data) = snp_data$probeset_id
    snp_data = snp_data[,which(colnames(snp_data) != "probeset_id")]
  } else {stop("Error: invalid filename for 'snp_data_file'")}
  
  if(file.exists(sample_qc_file)){
    sample_qc = read.table(sample_qc_file, sep="\t", header=T, stringsAsFactors = F)
    sample_qc = sample_qc[,1:7]
  } else {stop("Error: invalid filename for 'sample_qc_file'")}
  
  if(file.exists(ps_qc_file)){
    ps_qc = read.table(ps_qc_file, sep="\t", header=T, stringsAsFactors = F)
    rownames(ps_qc) = ps_qc$probeset_id
    if(identical(sort(rownames(snp_data)),sort(ps_qc$probeset_id))){
      ps_qc = ps_qc[match(rownames(snp_data),ps_qc$probeset_id),]
    } else {stop("Error: probeset IDs do not match between 'snp_data_file' and 'ps_qc_file'")}
  } else {stop("Error: invalid filename for 'ps_qc_file'")}
  
  sample_metadata = NULL
  if(!is.null(sample_meta_file)){
    if(file.exists(sample_meta_file)){
      sample_metadata = read.csv(sample_meta_file, stringsAsFactors = F)
      sample_metadata = sample_metadata[match(colnames(snp_data),sample_metadata[,1]),]
    } else {stop("Error: invalid filename for sample_meta_file. This file can be omitted.")}
  }
  
  sample_all_data = NULL
  if(!is.null(sample_meta_file)){
    if(file.exists(sample_meta_file)){
      sample_all_data = merge(sample_qc, sample_metadata, by = 1)
    } else {stop("Error: invalid filename for sample_meta_file. This file can be omitted.")}
  }
  
  leaf = list(snp_data        = snp_data, 
              ps_qc           = ps_qc, 
              sample_data     = sample_all_data)
  return(leaf)
}

########################################
# the point of this function is to filter snp_data and ps_qc by values in ConversionType and BestProbeset in ps_qc
# this fxn will filter on the columns specified in filter_col1 and filter_col2 by condition1 and condition2
leaf_filter = function(leaf_data = NULL, filter_col1 = "ConversionType", condition1 = "PolyHighResolution", filter_col2 = "BestProbeset", condition2 = 1){
  
  if(!is.null(leaf_data)){
    
    if(!is.null(filter_col1)){
      leaf_data$ps_qc = leaf_data$ps_qc[which(leaf_data$ps_qc[,filter_col1] == condition1),]
      leaf_data$snp_data = leaf_data$snp_data[rownames(leaf_data$ps_qc),]
    } else {stop("Error: Require at least one column and one condition")}
    
    if(!is.null(filter_col2)){
      leaf_data$ps_qc = leaf_data$ps_qc[which(leaf_data$ps_qc[,filter_col2] == condition2),]
      leaf_data$snp_data = leaf_data$snp_data[rownames(leaf_data$ps_qc),]
    } else {}
    
  } else {stop("Error: Object Not Found")}
  
  leaf = list(snp_data        = leaf_data$snp_data, 
              ps_qc           = leaf_data$ps_qc, 
              sample_data     = leaf_data$sample_data)
  return(leaf)
}

########################################
#Purpose is to recalculate sample call and heterozygous call rates

leaf_recalculate_sample_metrics = function(dataList = NULL){
  
  # Re-calculated call rate
  call_rate_recalculated = round(100 * apply(dataList$snp_data, 2, function(x) length(which(x >= 0))) / nrow(dataList$snp_data), digits = 3)
  dataList$sample_data$call_rate_recalculated = call_rate_recalculated[match(dataList$sample_data$Sample.Filename, names(call_rate_recalculated))]
  
  # Re-calculated heterozygous rate
  het_rate_recalculated = round(100 * apply(dataList$snp_data, 2, function(x) length(which(x == 1))) / apply(dataList$snp_data, 2, function(x) length(which(x >= 0))), digits = 3)
  dataList$sample_data$het_rate_recalculated = het_rate_recalculated[match(dataList$sample_data$Sample.Filename, names(het_rate_recalculated))]
  
  return(dataList)
}


