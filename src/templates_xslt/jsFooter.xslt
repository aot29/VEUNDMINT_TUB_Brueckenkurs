<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template name="jsFooter">
		<script>
		<![CDATA[

			viewmodel = {
			  // <JSCRIPTVIEWMODEL>
			  
			  ifobs: ko.observable("")
			}
			
			ko.bindingHandlers.evalmathjax = {
			    update: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
			      var value = valueAccessor(), allBindings = allBindingsAccessor();
			      var latex = ko.unwrap(value);
			      
			      var i;
			      latex = applyMVARLatex(latex);
			
			      if (element.childNodes[0]) {
			        // var sy = getScrollY();
			        var mathelement = MathJax.Hub.getAllJax(element)[0];
			        MathJax.Hub.Queue(["Text",mathelement,latex]);
			        // setScrollY(sy);
			      } else {
			        // while(element.childNodes[0]) { element.removeChild( element.childNodes[0] ); }
			      
			        var s = document.createElement('script');
			        s.type = "math/tex; mode=display";
			        try {
			          s.appendChild(document.createTextNode(latex));
			          element.appendChild(s);
			        } catch (e) {
			          s.text = latex;
			          element.appendChild(s);
			        }
			        MathJax.Hub.Queue(["Typeset",MathJax.Hub,element]);
			      }
			  }
			 };
			
			ko.applyBindings(viewmodel);
			
			
			$(document).ready(function () {
			  globalreadyHandler("");   
			});
			
			// <JSCRIPTPOSTMODEL>
		]]>
		</script>

	</xsl:template>

</xsl:stylesheet>