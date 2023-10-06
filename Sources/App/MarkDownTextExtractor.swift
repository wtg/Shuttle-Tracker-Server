import Markdown

struct MarkdownTextExtractor: MarkupWalker {
    
    private(set) var rawText = ""
    
    mutating func visitText(_ text: Text) {
        rawText.append(text.plainText)
    }
    
}