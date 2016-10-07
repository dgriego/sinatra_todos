// shows one way to layer some javascript
// into a web application
$(function() {
  // pops up dialog box to make sure
  // user wants to delete a todo or todo list
  $('form.delete').submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm('Are you sure? This cannot be undone!');
    if(ok) {
      // wraps the form in a jquery object
      // because we are inside of a jquery object on form
      // this will refer to the form element
      var form = $(this);

      // making a post request to sinatra to delete
      var request = $.ajax({
        url: form.attr("action"),
        method: "POST"
      });

      request.done(function(data, textStatus, jqXHR) {
        if(jqXHR.status === 204) {
          form.parent("li").remove();
        } else if (jqXHR.status === 200) {
          // data will be the string returned by the server
          document.location = data;
        }
      });
    }
  });
});
