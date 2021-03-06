##################################################
#  wabf_calculate_bayes_factor.R
#
#  $proj/Scripts/causality/bayes_MR/main_pipeline/wabf_calculate_bayes_factor.R
# 
#  This script calculates the MR stats (both frequentist and Bayesian) for SNP-cis-trans trios for the GTEx v8 data.
#
#  Author: Brian Jo
#
##################################################

#!/usr/bin/Rscript

# Manually import PATH
# .libPaths("/home/bj5/R/x86_64-redhat-linux-gnu-library/3.1")

args <-commandArgs(TRUE)
proj_dir = Sys.getenv('proj')

# Example
# args = c(1:6)
# args[1] = 'Muscle_Skeletal'
# args[2] = '1'
# args[3] = '1'
# args[4] = '20000'
# args[5] = '/tigress/BEE/RNAseq/Output/causality/gtex/bayes_MR/prep_files/'
# args[6] = '/tigress/BEE/RNAseq/Output/causality/gtex/bayes_MR/eqtls/Muscle_Skeletal/wabf_eqtls_'

tissue_name = args[1]
chr_number = args[2]
part_number = as.numeric(args[3])
partition_size = as.numeric(args[4])
prep_dir = args[5]
out_file = args[6]

library(MASS)
source("/tigress/BEE/RNAseq/Scripts/causality/bayes_MR/main_pipeline/wabf_functions.R")
load(paste0(prep_dir, tissue_name, '.RData'))

# Read in the genotype positions - both for MAF 1% and 5%
genotype_file_name = paste0(proj_dir, '/Data/Genotype/gtex/v8/ld_prune/GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_chr', chr_number, '_MAF_05_ld_pruned.RData')
load(genotype_file_name)
genotypes_all = genotype_matrix_master
genotype_file_name = paste0(proj_dir, '/Data/Genotype/gtex/v8/ld_prune/GTEx_Analysis_2017-06-05_v8_WholeGenomeSeq_838Indiv_chr', chr_number, '_MAF_01_ld_pruned.RData')
load(genotype_file_name)
genotypes_all = rbind(genotypes_all, genotype_matrix_master)
# This loads in the data frame "genotype_matrix_master"

# Get the appropriate partition
num_parts = ceiling(nrow(genotypes_all) / partition_size)
num_inds = ceiling(nrow(genotypes_all) / num_parts)
if (part_number == num_parts) {
  genotype_matrix = genotypes_all[c((((part_number-1)*num_inds)+1):nrow(genotypes_all)),]
} else {
  genotype_matrix = genotypes_all[c((((part_number-1)*num_inds)+1):(part_number*num_inds)),]
}
# There should be 838 indivs for genotype

# Fix the data type
genotype_matrix_temp = data.frame(lapply(genotype_matrix,as.numeric))
rownames(genotype_matrix_temp) = rownames(genotype_matrix)
colnames(genotype_matrix_temp) = colnames(genotype_matrix)
genotype_matrix = genotype_matrix_temp

# match the colnames to expression matrix
genotype_matrix = genotype_matrix[,colnames(expression_matrix)]
genotype_matrix_AA = genotype_matrix[,colnames(expression_matrix_AA)]
genotype_matrix_EA = genotype_matrix[,colnames(expression_matrix_EA)]

# Get the SNP positions
snp_positions = data.frame(ID = rownames(genotype_matrix), chr = sapply(rownames(genotype_matrix), function(x) {strsplit(x, '_')[[1]][1]}), pos = as.numeric(sapply(rownames(genotype_matrix), function(x) {strsplit(x, '_')[[1]][2]})))

# Parameter settings
# For now, let use the W value of 0.15^2 - roughly translating to 95% chance that the relative risk is between 2/3 and 3/2
cis_risk = 1.5
W = (log(cis_risk)/1.96)^2
# Say we expect roughly one out of 1e5 SNPs to be eQTLs
pi_1 = 1e-5
PO = (1-pi_1)/pi_1
# trans distance threshold - will set 1Mb for both
cis_threshold = 1000000
# PPA threshold for saving
cis_PPA_threshold = 0.5
trans_PPA_threshold = 0.5

abf_cis_eqtl_list_AA = list()
abf_cis_eqtl_list_EA = list()
abf_cis_eqtl_list = list()
abf_trans_eqtl_list_AA = list()
abf_trans_eqtl_list_EA = list()
abf_trans_eqtl_list = list()

# Let's first obtain the list of cis-eQTLs - PPA threshold of 0.5 for cis
# This task will be divided into EA and AA individuals and processed separately
# for (i in c(1:20)) {
for (i in c(1:nrow(genotype_matrix))) {
	print(i)
	snp = rownames(genotype_matrix)[i]
	# which genes are cis?
	cis_gene_pos = gene_positions[gene_positions$chr == paste0('chr', chr_number),]
	cis_genes = names(which((sapply(rownames(cis_gene_pos), function(x) {cis_gene_pos[x, 'start'] - cis_threshold <= snp_positions[i,'pos'] && gene_positions[x, 'end'] + cis_threshold >= snp_positions[i,'pos']}))))

	return_frame = calc_WABF_with_NAs(expression_matrix, genotype_matrix[i,], cov, W, PO)
	rownames(return_frame) = return_frame$gene
	return_frame_AA = calc_WABF_with_NAs(expression_matrix_AA, genotype_matrix_AA[i,], cov_AA, W, PO)
	rownames(return_frame_AA) = return_frame_AA$gene
	return_frame_EA = calc_WABF_with_NAs(expression_matrix_EA, genotype_matrix_EA[i,], cov_EA, W, PO)
	rownames(return_frame_EA) = return_frame_EA$gene

	if (is.null(return_frame)) {next}

	# Save cis eQTLs - threshold of 0.5
	if (length(cis_genes) > 0) {
		cis = return_frame[cis_genes,]
		cis_AA = return_frame_AA[cis_genes,]
		cis_EA = return_frame_EA[cis_genes,]
		vec1 = cis$ppa >= cis_PPA_threshold
		vec2 = cis_AA$ppa >= cis_PPA_threshold
		vec3 = cis_EA$ppa >= cis_PPA_threshold
		vec = vec1
		if (length(vec2) > 0) {vec = vec + vec2}
		if (length(vec3) > 0) {vec = vec + vec3}
		if (sum(vec) > 0) {
			save_inds = which(vec > 0)
			abf_cis_eqtl_list[[i]] = cis[save_inds,]
			abf_cis_eqtl_list_AA[[i]] = cis_AA[save_inds,]
			abf_cis_eqtl_list_EA[[i]] = cis_EA[save_inds,]
		}
	}

	# Save trans eQTLs - threshold of 0.05
	trans_genes = setdiff(rownames(expression_matrix), cis_genes)
	trans = return_frame[trans_genes,]
	trans_AA = return_frame_AA[trans_genes,]
	trans_EA = return_frame_EA[trans_genes,]
	vec1 = trans$ppa >= trans_PPA_threshold
	vec2 = trans_AA$ppa >= trans_PPA_threshold
	vec3 = trans_EA$ppa >= trans_PPA_threshold
	vec = vec1
	if (length(vec2) > 0) {vec = vec + vec2}
	if (length(vec3) > 0) {vec = vec + vec3}
	if (sum(vec) > 0) {
		save_inds = which(vec > 0)
		abf_trans_eqtl_list[[i]] = trans[save_inds,]
		abf_trans_eqtl_list_AA[[i]] = trans_AA[save_inds,]
		abf_trans_eqtl_list_EA[[i]] = trans_EA[save_inds,]
	}
}

abf_cis_eqtls = do.call('rbind', abf_cis_eqtl_list)
abf_cis_eqtls_AA = do.call('rbind', abf_cis_eqtl_list_AA)
abf_cis_eqtls_EA = do.call('rbind', abf_cis_eqtl_list_EA)

abf_trans_eqtls = do.call('rbind', abf_trans_eqtl_list)
abf_trans_eqtls_AA = do.call('rbind', abf_trans_eqtl_list_AA)
abf_trans_eqtls_EA = do.call('rbind', abf_trans_eqtl_list_EA)

# Save the resulting data frames with the parameter set as file name
save(abf_cis_eqtls, abf_cis_eqtls_AA, abf_cis_eqtls_EA, abf_trans_eqtls, abf_trans_eqtls_AA, abf_trans_eqtls_EA, file = paste0(out_file, 'chr_', chr_number, '_part_', part_number, '_cisPPA_', cis_PPA_threshold, '_transPPA_', trans_PPA_threshold, '.RData'))
