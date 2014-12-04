/**
 * I am the summary service
 * All I do is query a remote webservice to get a summary for a string
 */



<!-------------------------------------------------------------
<cfcomponent>

    <cffunction access="public" name="getSummary">

        <cfargument name="clipping_texto" type="string">

            <cfhttp method="post" url="http://127.0.0.1:5000/ajax_resumo" result="st_summary">
                <cfhttpparam type="formfield" name="texto" value="#arguments.clipping_texto#">
            </cfhttp>

        <cfreturn st_summary>

    </cffunction>

</cfcomponent>
--------------------------------------------------------------->
component {

    public function getSummary(string clipping_texto){
        txt_teste = "All in all you're just another brick in the wall";


        cfhttp(url='http://localhost:5000/ajax_resumo' method='post' result='st_summary'){
            cfhttpparam (type="formfield" name = "texto" value = clipping_texto);
        }

        // st_summary is a struct with a bunch of stuff
        // if there's a error, return an error message
        // if not, just the string we need

        if (len(st_summary.errordetail) > 0) {
            return "There was an error trying to use summary service";
        } else {
            return st_summary.filecontent;
        }
    }

}
