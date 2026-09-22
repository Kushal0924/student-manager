package com.example.studentapp;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;

@Entity
@Table(name = "students")
public class Student {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @NotBlank(message = "Name is required")
  @Column(nullable = false)
  private String name;

  @NotBlank(message = "Email is required")
  @Email(message = "Invalid email")
  @Column(nullable = false, unique = true)
  private String email;

  @NotBlank(message = "Course is required")
  @Column(nullable = false)
  private String course;

  @Min(value = 1, message = "Age must be positive")
  @Max(value = 120, message = "Age must be realistic")
  private Integer age;

  public Long getId() { return id; }
  public void setId(Long id) { this.id = id; }
  public String getName() { return name; }
  public void setName(String name) { this.name = name; }
  public String getEmail() { return email; }
  public void setEmail(String email) { this.email = email; }
  public String getCourse() { return course; }
  public void setCourse(String course) { this.course = course; }
  public Integer getAge() { return age; }
  public void setAge(Integer age) { this.age = age; }
}
