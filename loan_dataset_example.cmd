get attributes examples/loan_dataset_example/loan_dataset.attr
get attribute_values examples/loan_dataset_example/loan_dataset.attr.values
get training_examples examples/loan_dataset_example/loan_dataset.train.pat
get test_examples examples/loan_dataset_example/loan_dataset.test.pat
get network examples/loan_dataset_example/loan_dataset
set seed 1
set tree_size_limit 10
set min_sample 5000
lo_mofn examples/loan_dataset_example/loan_dataset.fidelity
test_fidelity
test_correctness
draw_tree_revisited examples/loan_dataset_example/loan_dataset.dot
quit