// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract LibraryBase{
    address owner;
    struct Book {
        string title;
        string author;
        uint copies;
    }
    Book[] public books;
    mapping(uint => Book) bookId;
    mapping(address => mapping(uint => bool)) hasBorrowed;
    //Events
    event BookAdded(string _title, string _author, uint _copies);
    event BookBorrowed(address borrower, uint _id);
    event BookReturned(address borrower, uint _id);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier validId(uint _id) {
        require(_id < books.length, "Invalid Book ID");
        _;
    }
    function addBook(string memory _title, string memory _author, uint _copies) public onlyOwner{
        Book memory book = Book(_title, _author, _copies);
        books.push(book);
        uint index = books.length - 1;
        bookId[index] = book;
        emit BookAdded(_title, _author, _copies);
    }
    function borrowBook(uint _id) public validId(_id) virtual {
        require(!hasBorrowed[msg.sender][_id], "Book already borrowed");
        require(books[_id].copies > 0, "Book inventory is empty");
        books[_id].copies--;
        hasBorrowed[msg.sender][_id] = true;
        emit BookBorrowed(msg.sender, _id);
    }
    function returnBook(uint _id) public validId(_id) virtual{
        require(hasBorrowed[msg.sender][_id], "Book not borrowed");
        books[_id].copies++;
        hasBorrowed[msg.sender][_id] = false;
        emit BookReturned(msg.sender, _id);
    }
}

contract LibraryAnalytics is LibraryBase{
    uint totalBorrowed;
    uint totalReturned;
    function borrowBook(uint _id) public virtual override {
        totalBorrowed ++;
        super.borrowBook(_id);
    }
    function returnBook(uint _id) public override {
        totalReturned ++;
        super.returnBook(_id);
    }
}

contract SchoolLibrary is LibraryAnalytics{
    mapping(address => bool) public isStudent;
    event StudentAdded(address _student, uint timestamp);
    function addStudents(address _student) public onlyOwner {
        require(!isStudent[_student], "Already a student");
        isStudent[_student] = true;
        emit StudentAdded(_student, block.timestamp);
    }
    function borrowBook(uint _id) public override {
        require(isStudent[msg.sender], "Not a student");
        super.borrowBook(_id);
    } 
}