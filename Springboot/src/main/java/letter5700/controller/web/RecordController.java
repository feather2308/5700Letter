package letter5700.controller.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/")
public class RecordController {

    @GetMapping("/")
    public String index() {
        return "home";
    }

    @GetMapping("/loading")
    public String loading() {
        return "loading";
    }

    @GetMapping("/result")
    public String result() {
        return "result";
    }

    @GetMapping("/result-detail")
    public String resultDetail() {
        return "result-detail";
    }
}
