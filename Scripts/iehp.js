(function ($) {
    var searchTmp, results, path, currentPage, pageGroupsTotal, startFrom, endFrom, queryString;

    $(document).ready(function () {
        //starting point for search query & pagination
        startFrom = 0;
       
        if (top.location.pathname === '/') {
            $(".eventBlock2").hide();
            $.when(
                //Home Page doctor Tab
                $.get('/api/sitecore/TabWrapper/TabWrapperCtrl?Tab1=DoctorTab&Qty1=3&Qty2=3&Qty3=2&pv=/Views/Components/_TabWrapperCtrl.cshtml', function (data1) {
                    $(".tabWrapper").html(data1);
                })
            ).then(function () {
                console.log("loading successful");
            });
        }

        if (window.location.href.indexOf("For-Members") > -1) {
            $("#hwTab1Tab, #hwTab2Tab, #hwTab3Tab, #hwTab4Tab, #hwTab5Tab, #hwTab6Tab").hide();
            $('#hwTab1Tab').show();

            $.when(
                //hwTab 1
                $.get('/api/sitecore/HwTabsWrapper/HwTabsWrapperCtrl?Tab=HwTab1&pv=/Views/Components/_HwTabsWrapperCtrl.cshtml', function (data2) {
                    $("#hwTab1Content").html(data2);
                })
            ).then(function () {
                console.log("loading member page successful");
            });
        }

        if (window.location.href.indexOf("search%20results") > -1) {
            performSearch();
        }


        //Mobile Menu
        $("#drawerOpen").on("click", function () {
            var $window = $(window);
            var windowSize = $window.width();
            var docHeight = $(document).height();

            if (windowSize < 501) {
                var distance = "0";
            } else if (windowSize >599 && windowSize < 990) {
                var distance = "50%";
            } else if (windowSize > 990 && windowSize < 1200) {
                var distance = "60%";
            }

            $("#drawer").css('height', docHeight);
            $("#drawer").css('display','block').animate({ left: distance }, 500);
        });

        $("#drawerClose").on("click", function () {
            $('#drawer').animate({ left: '150%' },
                {
                duration: 500,
                complete: function () {
                    $('#drawer').css('display','none');
                }
            });
        });
        
        //Home Page Tabs Section
        $("#doctorTab").on("click", function () {
            $(".eventBlock2, #urg, #pharm").hide();
            $('#doc').show();
            $.when(
                $.get('/api/sitecore/TabWrapper/TabWrapperCtrl?Tab1=DoctorTab&Qty1=3&Qty2=3&Qty3=2&pv=/Views/Components/_TabWrapperCtrl.cshtml', function (data1) {
                    $(".tabWrapper").html(data1);
                })
            );
        });

        $("#urgentTab").on("click", function () {
            $(".eventBlock2, #doc, #pharm").hide();
            $('#urg').show();
            $.when(
                $.get('/api/sitecore/TabWrapper/TabWrapperCtrl?Tab1=UrgentTab&Qty1=3&Qty2=3&Qty3=2&pv=/Views/Components/_TabWrapperCtrl.cshtml', function (data1) {
                    $(".tabWrapper").html(data1);
                })
            );
        });

        $("#pharmacyTab").on("click", function () {
            $(".eventBlock2, #doc, #urg").hide();
            $('#pharm').show();
            $.when(
                $.get('/api/sitecore/TabWrapper/TabWrapperCtrl?Tab1=PharmacyTab&Qty1=3&Qty2=3&Qty3=2&pv=/Views/Components/_TabWrapperCtrl.cshtml', function (data1) {
                    $(".tabWrapper").html(data1);
                })
            );
        });
       
        $(document).on("click", ".eventLink1", function () {
            $('.eventLink2').removeClass('active');
            $(".eventBlock1").css('display', 'flex');
            $(".eventBlock2").hide();
        });

        $(document).on("click", ".eventLink2", function () {
            $('.eventLink1').removeClass('active');
            $(".eventBlock2").css('display', 'flex');
            $(".eventBlock1").hide();
        });

        $(document).on("mouseenter", "#mainNavDropLink, #mainNavDropDown", function () {
            $("#mainNavDropDown").show();
        });

        $(document).on("mouseleave", "#mainNavDropLink, #mainNavDropDown", function () {
            $("#mainNavDropDown").hide();
        });

        $(document).on("mouseenter", "#searchLinkWrapper", function () {
            $("#searchLinkWrapper").addClass('open');
        });

        $(document).on("mouseleave", "#searchBox, #searchLinkWrapper", function () {
            $("#searchLinkWrapper").removeClass('open');
        });

        //Mega Nav's
        $(document).on("mouseenter", "#megaNavToggle", function () {
            $("#fadMegaNavMenu, #fmMegaNavMenu, #fpMegaNavMenu, #fcMegaNavMenu").hide();
            $("#fadMegaNavMenu").css('display', 'block');
        });

        //FAD Mega Nav
        $(document).on("mouseenter", "#megaNavToggle .navMenu li:nth-child(1)", function () {
            $("#fadMegaNavMenu, #fmMegaNavMenu, #fpMegaNavMenu, #fcMegaNavMenu").hide();
            $("#fadMegaNavMenu").css('display', 'block');
        });

        //FM Mega Nav
        $(document).on("mouseenter", "#megaNavToggle .navMenu li:nth-child(2)", function () {
            $("#fadMegaNavMenu, #fmMegaNavMenu, #fpMegaNavMenu, #fcMegaNavMenu").hide();
            $("#fmMegaNavMenu").css('display', 'block');
        });

        //FP Mega Nav
        $(document).on("mouseenter", "#megaNavToggle .navMenu li:nth-child(3)", function () {
            $("#fadMegaNavMenu, #fmMegaNavMenu, #fpMegaNavMenu, #fcMegaNavMenu").hide();
            $("#fpMegaNavMenu").css('display', 'block');
        });

        //FC Mega Nav
        $(document).on("mouseenter", "#megaNavToggle .navMenu li:nth-child(4)", function () {
            $("#fadMegaNavMenu, #fmMegaNavMenu, #fpMegaNavMenu, #fcMegaNavMenu").hide();
            $("#fcMegaNavMenu").css('display', 'block');
        });

        //Close mega navs
        $(document).on("mouseleave", "#subNavMenuWrapper, #fadMegaNavMenu, #fmMegaNavMenu, #fpMegaNavMenu, #fcMegaNavMenu", function () {
            $("#fadMegaNavMenu, #fmMegaNavMenu, #fpMegaNavMenu, #fcMegaNavMenu").css('display', 'none');
        });


        //Members Page
        $("#hwTab1").click(function () {
            $("#hwTab1Tab, #hwTab2Tab, #hwTab3Tab, #hwTab4Tab, #hwTab5Tab, #hwTab6Tab").hide();
            $('#hwTab1Tab').show();
            $.when(
                $.get('/api/sitecore/HwTabsWrapper/HwTabsWrapperCtrl?Tab=HwTab1&pv=/Views/Components/_HwTabsWrapperCtrl.cshtml', function (data3) {
                    $('#hwTab1Content').html(data3);
                })
            );
        });

        $("#hwTab2").click(function () {
            $("#hwTab1Tab, #hwTab2Tab, #hwTab3Tab, #hwTab4Tab, #hwTab5Tab, #hwTab6Tab").hide();
            $('#hwTab2Tab').show();
            $.when(
                $.get('/api/sitecore/HwTabsWrapper/HwTabsWrapperCtrl?Tab=HwTab2&pv=/Views/Components/_HwTabsWrapperCtrl.cshtml', function (data3) {
                    $('#hwTab2Content').html(data3);
                })
            );
        });

        $("#hwTab3").click(function () {
            $("#hwTab1Tab, #hwTab2Tab, #hwTab3Tab, #hwTab4Tab, #hwTab5Tab, #hwTab6Tab").hide();
            $('#hwTab3Tab').show();
            $.when(
                $.get('/api/sitecore/HwTabsWrapper/HwTabsWrapperCtrl?Tab=HwTab3&pv=/Views/Components/_HwTabsWrapperCtrl.cshtml', function (data3) {
                    $('#hwTab3Content').html(data3);
                })
            );
        });

        $("#hwTab4").click(function () {
            $("#hwTab1Tab, #hwTab2Tab, #hwTab3Tab, #hwTab4Tab, #hwTab5Tab, #hwTab6Tab").hide();
            $('#hwTab4Tab').show();
            $.when(
                $.get('/api/sitecore/HwTabsWrapper/HwTabsWrapperCtrl?Tab=HwTab4&pv=/Views/Components/_HwTabsWrapperCtrl.cshtml', function (data3) {
                    $('#hwTab4Content').html(data3);
                })
            );
        });

        $("#hwTab5").click(function () {
            $("#hwTab1Tab, #hwTab2Tab, #hwTab3Tab, #hwTab4Tab, #hwTab5Tab, #hwTab6Tab").hide();
            $('#hwTab5Tab').show();
            $.when(
                $.get('/api/sitecore/HwTabsWrapper/HwTabsWrapperCtrl?Tab=HwTab5&pv=/Views/Components/_HwTabsWrapperCtrl.cshtml', function (data3) {
                    $('#hwTab5Content').html(data3);
                })
            );
        });

        $("#hwTab6").click(function () {
            $("#hwTab1Tab, #hwTab2Tab, #hwTab3Tab, #hwTab4Tab, #hwTab5Tab, #hwTab6Tab").hide();
            $('#hwTab6Tab').show();
            $.when(
                $.get('/api/sitecore/HwTabsWrapper/HwTabsWrapperCtrl?Tab=HwTab6&pv=/Views/Components/_HwTabsWrapperCtrl.cshtml', function (data3) {
                    $('#hwTab6Content').html(data3);
                })
            );
        });

        $('.sbtn').on("click", function () {
            currentPage = 1;
            startFrom = 0;
            results = null;
            var searchTmp = $('#s').val(); 
            window.location.href = "http://iehp/search%20results.aspx?searchTmp=" + searchTmp;
        });

        //bind return key to searchBtn function
        $('#s').keypress(function (e) {
            if (e.which === 13) {
                $(this).blur();
                results = null;
                currentPage = 1;
                startFrom = 0;
                var searchTmp = $('#s').val();
                window.location.href = "http://iehp/search%20results.aspx?searchTmp=" + searchTmp;
                e.preventDefault();
            }
        });

        //next row functionality
        $(document).on('click', '#nextRowLink', function () {
            currentPage = currentPage + 1;
            $('#paginationHelper').html("<span class='pagText'>Viewing Page " + currentPage + " of " + pageGroupsTotal + "</span>");
            buildNextPageGroup();
        });

        //prev row functionality
        $(document).on('click', '#prevRowLink', function () {
            if (currentPage > 1) {
                currentPage = currentPage - 1;
            }

            $('#paginationHelper').html("<span class='pagText'>Viewing Page " + currentPage + " of " + pageGroupsTotal + "</span>");
            buildPrevPageGroup();
        });

        //resultItem functionality 
        $(document).on('click', 'a.itemNum', function () {
            var linkId = $(this).attr('id');
            parseInt(startFrom);

            if (linkId == 1) {
                startFrom = 0;
            } else {
                linkId = linkId + '0';
                parseInt(linkId);
                startFrom = linkId - 10;
            }

            endFrom = startFrom + 10;
            $('#paginationHelper').html("<span class='pagText'>Viewing Page " + currentPage + " of " + pageGroupsTotal + " |" + " Showing results " + startFrom + '-' + endFrom + " of " + results + "</span>");

            performSearch();
        });

        function performSearch() {
            //parse querystring
            var searchTerm = getUrlParameter('searchTmp');

            // build querystring & add select filter 
            var path = "http://localhost:8987/solr/iehp_sitecore_web_index/select?q=_content:";

            //querystring to write to resultsDiv. Show 10 results at a time.
            queryString = path + searchTerm + "&hl=true&hl.fl=_content&hl.usePhraseHighlighter=true&hl.requireFieldMatch=true&omitHeader=true&fl=highlighting,_name,_fullpath,_content,extension_t_en&start=" + startFrom + "&rows=10000&wt=json";

            //performQuery
            processQuery();
        }

        function showResults(data) {
            $.getJSON(queryString, function (data) {
                if (results == null) {
                    results = data.response.docs.length;
                    pageGroupsCalc();
                    buildFirstPageGroup(data);
                }

                pageGroupsCalc();
                writeResultsData(data);
            });
        }

        function pageGroupsCalc() {
            if ($('#paginationHelper').is(':empty')) {
                pageGroupsTotal = Math.ceil(results / 10 / 5);
                $('#paginationHelper').html("<span class='pagText'>Viewing Page " + currentPage + " of " + pageGroupsTotal + "|" + " Showing results 1-10 of " + results + "</span>");
            }

            if (results <= 10) {
                $('#paginationHelper').html("<span class='pagText'>Viewing Page " + currentPage + " of 1 " + "|" + " Showing results 1-" + results + " of " + results + "</span>");

                // 2 page groups
            } else if (results > 50 && results < 100) {
                pageGroupsTotal = 2;
            } else {
                pageGroupsTotal = Math.ceil(results / 10 / 5);
            }
        }

        function buildFirstPageGroup(data) {
            //on first run assume you're on page 1 and disable prev link
            $('#paginationWrapper').html("<span class='prevDisabled'><< prev</span>");

            //how many items to display in paginationWrapper
            var resultBlock = Math.ceil(results / 10);

            if (resultBlock < 6) {
                for (a = 1; a <= resultBlock; a++) {
                    $('#paginationWrapper').append("<a href='#' id='" + a + "' class='itemNum'>" + a + '</a>');
                }

                $('#paginationWrapper').append("<span class='nextDisabled'>next >></span>");

            } else {
                for (a = 1; a < 6; a++) {
                    $('#paginationWrapper').append("<a href='#' id='" + a + "' class='itemNum'>" + a + '</a>');
                }

                $('#paginationWrapper').append("<a href='#' id='nextRowLink'>" + 'next >>' + '</a>');
            }
        }

        function buildNextPageGroup(data) {
            //starting point for new result numbers
            var startRowNum = parseInt($('#paginationWrapper a.itemNum:last').text()) + 1;
            console.log(startFrom);

            //need to show results from last pageNumber clicked
            //if (startFrom == 0 || startFrom == null) {
            //    var startFromTmp = 1;
            //    var endFromTmp = 10;
            //}

            //$('#paginationHelper').html("<span class='pagText'>Viewing Page " + currentPage + " of " + pageGroupsTotal + "|" + " Showing results " + startFromTmp + "-" + endFromTmp  + " of " + results + "</span>");
            $('#paginationWrapper').html("<a href='#' id='prevRowLink'>" + '<< prev' + '</a>');

            //second page results numbering (51-100) results which should be (6-11) page numbers
            if (results > 59 && results < 101) {
                var endNum = Math.ceil(results / 10 / 5);

                for (a = startRowNum; a < startRowNum + endNum; a++) {
                    $('#paginationWrapper').append("<a href='#' id='" + a + "' class='itemNum'>" + a + '</a>');
                }

                $('#paginationWrapper').append("<span class='nextDisabled'>next >></span>");

            } else {
                for (a = startRowNum; a < startRowNum + 5; a++) {
                    $('#paginationWrapper').append("<a href='#' id='" + a + "' class='itemNum'>" + a + '</a>');
                }

                //end check
                if (currentPage == pageGroupsTotal) {
                    $('#paginationWrapper').append("<span class='nextDisabled'>next >></span>");
                } else {
                    $('#paginationWrapper').append("<a href='#' id='nextRowLink'>" + 'next >>' + '</a>');
                }
            }
        }

        function buildPrevPageGroup(data) {
            //starting point for new result numbers
            var endRowNum = parseInt($('#paginationWrapper a.itemNum:first').text());
            var startRowNum = endRowNum - 5;

            //start check
            if (currentPage == 1) {
                $('#paginationWrapper').html("<span class='prevDisabled'><< prev</span>");

                for (a = 1; a < 6; a++) {
                    $('#paginationWrapper').append("<a href='#' id='" + a + "' class='itemNum'>" + a + '</a>');
                }

                $('#paginationWrapper').append("<a href='#' id='nextRowLink'>" + 'next >>' + '</a>');

            } else {
                $('#paginationWrapper').html("<a href='#' id='prevRowLink'>" + '<< prev' + '</a>');

                for (a = startRowNum; a < endRowNum; a++) {
                    $('#paginationWrapper').append("<a href='#' id='" + a + "' class='itemNum'>" + a + '</a>');
                }

                $('#paginationWrapper').append("<a href='#' id='nextRowLink'>" + 'next >>' + '</a>');
            }
        }

        

        function writeResultsData(data) {
            $('#results').html('');

            //determine if results is less than 10 (not going to loop through 10 items which is a standard list)
            if (results < 10) {
                for (i = 0; i < results; i++) {
                    //determine doc type & build item link
                    if (data.response.docs[i].extension_t_en == 'undefined') {
                        itemLink = 'http://iehp/' + data.response.docs[i]._fullpath.replace('/sitecore/content/', '');
                        altTag = data.response.docs[i]._name;

                    } else if (data.response.docs[i].extension_t_en == 'pdf' || data.response.docs[i].extension_t_en == 'doc' || data.response.docs[i].extension_t_en == 'txt' || data.response.docs[i].extension_t_en == 'rtf') {
                        var itemLink = 'http://iehp/' + '-/media/' + data.response.docs[i]._fullpath + '.ashx';
                        var altTag = data.response.docs[i]._name;

                    } else {
                        itemLink = 'http://iehp/' + data.response.docs[i]._fullpath.replace('/sitecore/content/', '');
                        altTag = data.response.docs[i]._name;
                    }

                    //item description
                    var descriptTemp = data.response.docs[i]._content.toString();
                    var descriptTempShort = descriptTemp.substr(0, 135);

                    //write item(s) to div
                    $('#results').append("<li><a href='" + itemLink + "'alt='" + altTag + "'><span class=resultName>" + data.response.docs[i]._name + "</span></a><Br />" + descriptTempShort + '...' + '</li><span class="divider"></span>');
                }

                //more than 10 results, standard 10 per page
            } else {
                for (i = 0; i < 10; i++) {
                    //determine doc type & build item link
                    if (data.response.docs[i].extension_t_en == 'undefined') {
                        itemLink = 'http://iehp/' + data.response.docs[i]._fullpath.replace('/sitecore/content/', '');
                        altTag = data.response.docs[i]._name;

                    } else if (data.response.docs[i].extension_t_en == 'pdf' || data.response.docs[i].extension_t_en == 'doc' || data.response.docs[i].extension_t_en == 'txt' || data.response.docs[i].extension_t_en == 'rtf') {
                        var itemLink = 'http://iehp/' + '-/media/' + data.response.docs[i]._fullpath + '.ashx';
                        var altTag = data.response.docs[i]._name;

                    } else {
                        itemLink = 'http://iehp/' + data.response.docs[i]._fullpath.replace('/sitecore/content/', '');
                        altTag = data.response.docs[i]._name;
                    }

                    //item description
                    var descriptTemp = data.response.docs[i]._content.toString();
                    var descriptTempShort = descriptTemp.substr(0, 135);

                    //write item(s) to div
                    $('#results').append("<li><a href='" + itemLink + "'alt='" + altTag + "'><span class=resultName>" + data.response.docs[i]._name + "</span></a><Br />" + descriptTempShort + '...' + '</li><span class="divider"></span>');
                }
            }
        }
        

        function processQuery(data) {
            return $.ajax({
                type: "GET",
                dataType: "json",
                url: queryString,
                cache: false,
                beforeSend: function () {
                    $('#loading').show();
                },
                complete: function () {
                    $('#loading').hide();
                },
                success: function (data) {
                    showResults(data);
                },
                error: function (request, status, error) {
                    console.log(request.responseText);
                }
            });
        }

        function showResults(data) {
            $.getJSON(queryString, function (data) {
                if (results == null) {
                    results = data.response.docs.length;
                    pageGroupsCalc();
                    buildFirstPageGroup(data);
                }

                pageGroupsCalc();
                writeResultsData(data);
            });
        }

        function getUrlParameter(sParam) {
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;

            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');

                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };

        //remove extra chars from view msg - only playlistID chars
        //var playlistTmp = tmp.slice(14, 48);

        //$('#videoPlaylist').youtube_video({
        //    playlist: playlistTmp,
        //    playlist_type: 'horizontal',
        //    show_controls_on_load: false
        //});


        //$("#hwTab1, #hwTab2, #hwTab3, #hwTab4, #hwTab5, #hwTab6").click(function (event) {
        //    var linkID = (event.target.id);
        //    $("#hwTab1Tab, #hwTab2Tab, #hwTab3Tab, #hwTab4Tab, #hwTab5Tab, #hwTab6Tab").hide();
        //    $('#' + linkID + 'Tab').show();

        //    $.when(
        //        $.get('/api/sitecore/HwTabsWrapper/HwTabsWrapperCtrl?Tab='+linkID+'&pv=/Views/Components/_HwTabsWrapperCtrl.cshtml', function (data3) {
        //            $('#' + linkID + 'Content').html(data3);
        //        })
        //    ).then(function () {
        //        console.log("loading" + linkID + "successful");
        //    });
        //});


       

    });
})(jQuery);

