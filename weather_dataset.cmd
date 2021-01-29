get attributes examples/weather_example/weather.attr
get attribute_values examples/weather_example/weather.attr.values
get ontofilename libs/simple-weather-ontology.owl
get ontology examples/weather_example/weather.onto
get training_examples examples/weather_example/weather.train.pat
get test_examples examples/weather_example/weather.test.pat
get network examples/weather_example/weather
set use_ontology 0
set seed 9
set tree_size_limit 6
set min_sample 1000
lo_mofn examples/weather_example/weather.fidelity
test_fidelity
test_correctness
draw_tree_revisited examples/weather_example/weather.dot
print_rules examples/weather_example/weather.rules
quit