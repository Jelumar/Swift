package twa.symfonia.view.window;

import java.awt.Font;
import java.awt.event.ActionEvent;
import java.util.Vector;

import javax.swing.JLabel;
import javax.swing.SwingConstants;
import javax.swing.event.ListSelectionEvent;

import twa.symfonia.config.Configuration;
import twa.symfonia.controller.ViewController;
import twa.symfonia.service.xml.XmlReaderInterface;
import twa.symfonia.view.component.SymfoniaJButton;

/**
 * Fenster zur Selektion der Aufgabe, die der Nutzer ausführen möchte.
 * 
 * @author angermanager
 */
public class OptionSelectionWindow extends AbstractWindow
{

    /**
     * Optionsschalter
     */
    private final Vector<SymfoniaJButton> options;

    /**
     * Titel
     */
    private final JLabel title;

    /**
     * Beschreibung
     */
    private final JLabel text;

    /**
     * {@inheritDoc}
     * 
     * @throws WindowException
     */
    public OptionSelectionWindow(final int w, final int h, final XmlReaderInterface reader) throws WindowException
    {
        super(w, h, reader);

        final int titleSize = Configuration.getInteger("defaults.font.title.size");
        final int textSize = Configuration.getInteger("defaults.font.text.size");

        try
        {
            final String optionTitle = this.reader.getString("UiText/CaptionOptionWindow");
            final String optionText = this.reader.getString("UiText/DescriptionOptionWindow");

            title = new JLabel(optionTitle);
            title.setHorizontalAlignment(SwingConstants.CENTER);
            title.setBounds(10, 10, w - 20, 30);
            title.setFont(new Font(Font.SANS_SERIF, 1, titleSize));
            title.setVisible(true);
            getRootPane().add(title);

            text = new JLabel("<html><div align='justify'>" + optionText + "</div></html>");
            text.setVerticalAlignment(SwingConstants.TOP);
            text.setBounds(10, 50, w - 70, h - 300);
            text.setFont(new Font(Font.SANS_SERIF, 0, textSize));
            text.setVisible(true);
            getRootPane().add(text);

            options = new Vector<SymfoniaJButton>();
            for (int i = 0; i < 6; i++)
            {
                final String caption = this.reader.getString("UiText/ButtonOptionWindow" + i);
                final SymfoniaJButton b = new SymfoniaJButton(caption);
                b.setBounds(60, 150 + (i * 35), w - 120, 30);
                b.addActionListener(this);
                b.setVisible(true);
                getRootPane().add(b);
                options.add(b);
            }
            
            // Not implemented!
            options.get(3).setEnabled(false);
            options.get(4).setEnabled(false);
            options.get(5).setEnabled(false);
        } catch (final Exception e)
        {
            throw new WindowException(e);
        }

        getRootPane().setVisible(false);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void handleActionEvent(final ActionEvent aE)
    {
        // QSB zusammenstellen
        if (aE.getSource() == options.get(0))
        {
            ViewController.getInstance().getWindow("BundleSelectionWindow").show();
            hide();
        }

        // Dokumentation anzeigen
        if (aE.getSource() == options.get(1))
        {
            if (Configuration.isDebug()) {
                ViewController.getInstance().openLocalPage("../../doc/index.html");
            }
            else {
                ViewController.getInstance().openLocalPage("doc/index.html");
            }
        }

        // Basisskripte exportieren
        if (aE.getSource() == options.get(2))
        {
            ViewController.getInstance().getWindow("SaveBaseScriptsWindow").show();
            hide();
        }

        // Self-Update
        if (aE.getSource() == options.get(5))
        {
            ViewController.getInstance().getWindow("SelfUpdateWindow").show();
            hide();
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void handleValueChanged(final ListSelectionEvent a)
    {

    }
}
