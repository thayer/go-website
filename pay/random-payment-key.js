function randomNumber(len) {
    var randomNumber;
    var n = '';

    for(var count = 0; count < len; count++) {
        randomNumber = Math.floor(Math.random() * 10);
        n += randomNumber.toString();
    }
    return document.getElementById("element_12").value = n;
}
