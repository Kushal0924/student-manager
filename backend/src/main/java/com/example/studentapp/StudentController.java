package com.example.studentapp;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/students")
@CrossOrigin(origins = "*")
public class StudentController {

  private final StudentRepository repo;

  public StudentController(StudentRepository repo) {
    this.repo = repo;
  }

  @GetMapping
  public List<Student> all() {
    return repo.findAll();
  }

  @GetMapping("/{id}")
  public Student one(@PathVariable Long id) {
    return repo.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Student not found"));
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public Student create(@Valid @RequestBody Student s) {
    s.setId(null);
    return repo.save(s);
  }

  @PutMapping("/{id}")
  public Student update(@PathVariable Long id, @Valid @RequestBody Student s) {
    Student existing = repo.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Student not found"));
    existing.setName(s.getName());
    existing.setEmail(s.getEmail());
    existing.setCourse(s.getCourse());
    existing.setAge(s.getAge());
    return repo.save(existing);
  }

  @DeleteMapping("/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void delete(@PathVariable Long id) {
    if (!repo.existsById(id)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Student not found");
    }
    repo.deleteById(id);
  }
}
