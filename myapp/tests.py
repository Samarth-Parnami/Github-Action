from django.test import TestCase
from .views import covered_function
# Create your tests here.

class CoveringCoveredFunctionTest(TestCase):
    def test_covered_function(self):
        covered_function()
