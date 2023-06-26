from django.test import TestCase
from .views import covered_function, added_new_function
# Create your tests here.

class CoveringCoveredFunctionTest(TestCase):
    def test_covered_function(self):
        covered_function()

    def test_added_new_function(self):
        added_new_function()
