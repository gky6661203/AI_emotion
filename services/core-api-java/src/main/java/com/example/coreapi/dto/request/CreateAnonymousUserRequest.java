
package com.example.coreapi.dto.request;

public class CreateAnonymousUserRequest {
    private String nickname;
    private String campus;
    private Integer enrollmentYear;

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public String getCampus() { return campus; }
    public void setCampus(String campus) { this.campus = campus; }

    public Integer getEnrollmentYear() { return enrollmentYear; }
    public void setEnrollmentYear(Integer enrollmentYear) { this.enrollmentYear = enrollmentYear; }
}
