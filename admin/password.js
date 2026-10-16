function checkPassword(event) {
    let password = document.getElementById("password").value;
    let Cpassword = document.getElementById("Cpassword").value;

    if (password !== Cpassword) {
        alert("Passwords do not match!");
        event.preventDefault();  
        return false;
    }

    if (password.length < 7) {
        alert("Password must be at least 7 characters long!");
        event.preventDefault();  
        return false;
    }

    return true;
}


document.getElementById('registration-form').addEventListener('submit', checkPassword);
