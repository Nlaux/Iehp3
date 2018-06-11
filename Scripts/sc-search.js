
var templateID, url;

    $(document).ready(function () {
    $('#submit').on("click", function () {

        var templateTemp = $('#templateID').val();
        var inputTemp = $('#fieldVal').val();
        var url = "http://iehp/sitecore/api/ssc/item/" + templateTemp + "?fields=" + inputTemp;

        performSearch();

        function performSearch() {
            $.getJSON(url)
                .done(function (data) {
                    $.each(data, function (i, data) {
                        $('#results').html(i + ": " + data);
                    });

                })
                .fail(function (jqxhr, textStatus, error) {
                    var err = textStatus + ", " + error;
                    alert("Request Failed: " + err);
                });
        }

    });

});
