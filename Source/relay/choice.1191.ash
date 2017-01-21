import "relay/Source_Terminal_GUI.ash";
import "relay/choice.ash";
//Choice	override

void main(string page_text_encoded)
{
	string page_text = page_text_encoded.decodePageText();
	handleSourceTerminalChoiceOverride(page_text);
}