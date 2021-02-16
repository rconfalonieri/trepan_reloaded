#'dataset': ['loan-kt-num' , 'loan-kt-num-r1', 'loan-kt-num-r2', 'loan-kt-imp-num', 'loan-kt-imp-num-r1', 
# 'loan-kt-imp-num-r2', 'loan-kt-dropna-num', 'loan-kt-dropna-num-r1', 'loan-kt-dropna-num-r2'],

config_loan = {
        'tree_size' : 10,
        'ontology'  : 0,
        'data_path' : 'data/loan',
        'datasets' : ['loan-kt-num' , 'loan-kt-num-r1', 'loan-kt-num-r2'], 
        'use_case': 'loan',
        'class_nr'  : 2,
        'cross_validation_nr' : 10,
        'class_label' : 'Loan_Status'
}
