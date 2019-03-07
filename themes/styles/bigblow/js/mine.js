// Collapse all headers
function hsCollapseAllResearch() {
    $('#content .hsExpanded .research').each(function() {
        hsCollapse($(this).children(':header'));
    });
}
