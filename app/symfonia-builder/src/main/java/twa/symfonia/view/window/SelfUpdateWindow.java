package twa.symfonia.view.window;

import java.awt.Font;
import java.awt.event.ActionEvent;

import javax.swing.SwingConstants;
import javax.swing.event.ListSelectionEvent;

import org.jdesktop.swingx.JXLabel;

import twa.symfonia.config.Configuration;
import twa.symfonia.controller.ViewController;
import twa.symfonia.service.xml.XmlReaderInterface;
import twa.symfonia.view.component.SymfoniaJButton;

/**
 * 
 * @author mheller
 *
 */
public class SelfUpdateWindow extends AbstractWindow
{

    /**
     * Singleton Instanz
     */
    private static SelfUpdateWindow instance;

    /**
     * Titel des Fensters (Label).
     */
    private JXLabel title;

    /**
     * Beschreibungstext des Fensters.
     */
    private JXLabel text;

    /**
     * Buttun zum anzeigen des nächsten Fensters.
     */
    private SymfoniaJButton updateMaster;

    /**
     * Beschreibungstext des Fensters.
     */
    private JXLabel updateMasterLabel;

    /**
     * Buttun zum anzeigen des nächsten Fensters.
     */
    private SymfoniaJButton updateDev;

    /**
     * Beschreibungstext des Fensters.
     */
    private JXLabel updateDevLabel;

    /**
     * Buttun zum anzeigen des vorherigen Fensters.
     */
    private SymfoniaJButton back;

    /**
     * Constructor
     */
    public SelfUpdateWindow()
    {
        super();
    }

    /**
     * Gibt die Singleton-Instanz des Fensters zurück.
     * 
     * @return Singleton
     */
    public static SelfUpdateWindow getInstance()
    {
        if (instance == null)
        {
            instance = new SelfUpdateWindow();
        }
        return instance;
    }

    /**
     * {@inheritDoc}
     * 
     * @throws WindowException
     */
    public void initalizeComponent(final int w, final int h, final XmlReaderInterface reader) throws WindowException
    {
        super.initalizeComponents(w, h, reader);
        this.reader = reader;

        final int titleSize = Configuration.getInteger("defaults.font.title.size");
        final int textSize = Configuration.getInteger("defaults.font.text.size");

        try
        {
            final String updateTitle = this.reader.getString("UiText/CaptionUpdateWindow");
            final String updateText = this.reader.getString("UiText/DescriptionUpdateWindow");
            final String updateButton = this.reader.getString("UiText/ButtonUpdate");
            final String backButton = this.reader.getString("UiText/ButtonBack");
            final String updateMasterDesc = this.reader.getString("UiText/CheckoutMaster");
            final String updateDevDesc = this.reader.getString("UiText/CheckoutDevelopment");

            title = new JXLabel(updateTitle);
            title.setHorizontalAlignment(SwingConstants.CENTER);
            title.setBounds(10, 10, w - 20, 30);
            title.setFont(new Font(Font.SANS_SERIF, 1, titleSize));
            title.setVisible(true);
            getRootPane().add(title);

            text = new JXLabel(updateText);
            text.setLineWrap(true);
            text.setVerticalAlignment(SwingConstants.TOP);
            text.setBounds(10, 50, w - 70, h - 300);
            text.setFont(new Font(Font.SANS_SERIF, 0, textSize));
            text.setVisible(true);
            getRootPane().add(text);

            updateMaster = new SymfoniaJButton(updateButton);
            updateMaster.setBounds((w / 2) - 100, (int) (h * 0.35) + 15, 200, 30);
            updateMaster.addActionListener(this);
            updateMaster.setVisible(true);
            getRootPane().add(updateMaster);

            updateMasterLabel = new JXLabel(updateMasterDesc);
            updateMasterLabel.setVerticalAlignment(SwingConstants.TOP);
            updateMasterLabel.setHorizontalAlignment(SwingConstants.CENTER);
            updateMasterLabel.setBounds(10, (int) (h * 0.35) - 15, w - 40, 30);
            updateMasterLabel.setFont(new Font(Font.SANS_SERIF, 0, textSize));
            updateMasterLabel.setVisible(true);
            getRootPane().add(updateMasterLabel);

            updateDev = new SymfoniaJButton(updateButton);
            updateDev.setBounds((w / 2) - 100, (int) (h * 0.55) + 15, 200, 30);
            updateDev.addActionListener(this);
            updateDev.setVisible(true);
            getRootPane().add(updateDev);

            updateDevLabel = new JXLabel(updateDevDesc);
            updateDevLabel.setVerticalAlignment(SwingConstants.TOP);
            updateDevLabel.setHorizontalAlignment(SwingConstants.CENTER);
            updateDevLabel.setBounds(10, (int) (h * 0.55) - 15, w - 40, 30);
            updateDevLabel.setFont(new Font(Font.SANS_SERIF, 0, textSize));
            updateDevLabel.setVisible(true);
            getRootPane().add(updateDevLabel);

            back = new SymfoniaJButton(backButton);
            back.setBounds(25, h - 70, 130, 30);
            back.addActionListener(this);
            back.setVisible(true);
            getRootPane().add(back);
        }
        catch (final Exception e)
        {
            throw new WindowException(e);
        }

        getRootPane().setVisible(false);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void show()
    {
        super.show();

        System.out.println("Debug: Show " + this.getClass().getName());
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void hide()
    {
        super.hide();

        System.out.println("Debug: Hide " + this.getClass().getName());
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void handleActionEvent(final ActionEvent aE)
    {
        // Zurück
        if (aE.getSource() == back)
        {
            OptionSelectionWindow.getInstance().show();
            hide();
        }

        // Update Master
        if (aE.getSource() == updateMaster)
        {
            ViewController.getInstance().selfUpdateMaster();
        }

        // Update Dev
        if (aE.getSource() == updateDev)
        {
            ViewController.getInstance().selfUpdateDevelopment();
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