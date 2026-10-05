import std.conv : ConvException, to;
import std.math : isFinite;
import std.stdio : File, readln, stderr, writeln, writefln;
import std.string : chomp, indexOf, strip;

struct Student {
    string name;
    double grade;
}

// Input format:
// student_count
// name;grade
// ...
// Grades from 2 to 5 inclusive are accepted. The output file name can be
// passed as the first command-line argument; the default is students.txt.
void main(string[] args) {
    enum double minimumGrade = 2.0;
    enum double maximumGrade = 5.0;
    const filePath = args.length > 1 ? args[1] : "students.txt";

    const countLine = readln();
    if (countLine is null) {
        stderr.writeln("Student count is required.");
        return;
    }

    size_t studentCount;
    try {
        studentCount = to!size_t(countLine.strip());
    } catch (ConvException) {
        stderr.writeln("Student count must be a positive integer.");
        return;
    }

    if (studentCount == 0) {
        stderr.writeln("Student count must be positive.");
        return;
    }

    auto outputFile = File(filePath, "w");
    size_t savedCount = 0;

    while (savedCount < studentCount) {
        const inputLine = readln();
        if (inputLine is null) break;

        const line = inputLine.chomp();
        const separatorPosition = line.indexOf(';');
        if (separatorPosition < 0) {
            stderr.writeln("Skipped invalid record. Expected: name;grade");
            continue;
        }

        const name = line[0 .. separatorPosition].strip();
        const gradeText = line[separatorPosition + 1 .. $].strip();
        if (name.length == 0 || name.indexOf('\t') >= 0) {
            stderr.writeln("Skipped record with an invalid name.");
            continue;
        }

        double grade;
        try {
            grade = to!double(gradeText);
        } catch (ConvException) {
            stderr.writeln("Skipped record with a non-numeric grade.");
            continue;
        }

        if (!isFinite(grade) || grade < minimumGrade || grade > maximumGrade) {
            stderr.writeln("Skipped grade outside the range from 2 to 5.");
            continue;
        }

        outputFile.writefln("%s\t%.2f", name, grade);
        ++savedCount;
    }
    outputFile.close();

    if (savedCount != studentCount) {
        stderr.writeln("Not enough valid student records were entered.");
        return;
    }

    Student[] students;
    double totalGrade = 0.0;
    auto inputFile = File(filePath, "r");

    foreach (rawLine; inputFile.byLine()) {
        const line = rawLine.chomp();
        const separatorPosition = line.indexOf('\t');
        if (separatorPosition < 0) continue;

        const name = line[0 .. separatorPosition].idup;
        const grade = to!double(line[separatorPosition + 1 .. $]);
        students ~= Student(name, grade);
        totalGrade += grade;
    }
    inputFile.close();

    const averageGrade = totalGrade / students.length;
    writefln("Average grade: %.2f", averageGrade);
    writeln("Students above average:");

    foreach (student; students) {
        if (student.grade > averageGrade) {
            writefln("%s: %.2f", student.name, student.grade);
        }
    }
}
