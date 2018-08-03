package com.example.restsample;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * Hello Controller.
 *
 */
@RestController
@RequestMapping("${api.version}")
public class HelloController {

    /**
     * Get greeting message.
     *
     * @return greeting message
     */
    @RequestMapping("/")
    public final String index() {
        return "Greetings from Spring Boot!";
    }

}

