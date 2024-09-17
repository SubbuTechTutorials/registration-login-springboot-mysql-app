package com.example.registrationlogindemo.service;

import com.example.registrationlogindemo.entity.Login;
import com.example.registrationlogindemo.repository.LoginRepository;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@SpringBootTest
public class LoginServiceTest {

    @Mock
    private LoginRepository loginRepository;

    @InjectMocks
    private LoginService loginService;

    @Test
    public void testFindUserByUsername() {
        // Setup mock user
        Login user = new Login();
        user.setUsername("testUser");
        user.setPassword("testPass");

        // Mock the repository call
        when(loginRepository.findByUsername("testUser")).thenReturn(user);

        // Call the service method
        Login result = loginService.findUserByUsername("testUser");

        // Assertions
        assertEquals("testUser", result.getUsername());
        assertEquals("testPass", result.getPassword());
    }
}
