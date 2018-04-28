package twa.symfonia.view.window;

import java.awt.Color;
import java.awt.Font;
import java.awt.event.ActionEvent;
import java.io.File;
import java.util.regex.PatternSyntaxException;

import javax.swing.JTextField;
import javax.swing.SwingConstants;
import javax.swing.event.ListSelectionEvent;

import org.jdesktop.swingx.JXLabel;

import twa.symfonia.config.Configuration;
import twa.symfonia.service.xml.XmlReaderInterface;
import twa.symfonia.view.component.SymfoniaJButton;

/**
 * Vorlage für Speicherdialoge
 * 
 * @author angermanager
 *
 */
abstract public class AbstractSaveWindow extends AbstractWindow
{

    /**
     * Titel
     */
    protected JXLabel title;

    /**
     * Text
     */
    protected JXLabel text;

    /**
     * Verzeichnis wählen
     */
    protected SymfoniaJButton choose;

    /**
     * 
     */
    protected JTextField fileNameField;

    /**
     * Verzeichnis wählen
     */
    protected SymfoniaJButton save;

    /**
     * Text
     */
    protected JXLabel info;

    /**
     * Zurück
     */
    protected SymfoniaJButton back;

    /**
     * Constructor
     */
    public AbstractSaveWindow()
    {
        super();
    }

    /**
     * @throws WindowException
     * 
     */
    @Override
    public void initalizeComponents(final int w, final int h, final XmlReaderInterface reader) throws WindowException
    {
        super.initalizeComponents(w, h, reader);
        this.reader = reader;

        final int titleSize = Configuration.getInteger("defaults.font.title.size");
        final int textSize = Configuration.getInteger("defaults.font.text.size");

        try
        {
            final String chooseText = this.reader.getString("UiText/ButtonSearch");
            final String saveText = this.reader.getString("UiText/ButtonSave");
            final String backButton = this.reader.getString("UiText/ButtonBack");

            title = new JXLabel();
            title.setHorizontalAlignment(SwingConstants.CENTER);
            title.setBounds(10, 10, w - 20, 30);
            title.setFont(new Font(Font.SANS_SERIF, 1, titleSize));
            title.setVisible(true);
            getRootPane().add(title);

            text = new JXLabel();
            text.setLineWrap(true);
            text.setVerticalAlignment(SwingConstants.TOP);
            text.setBounds(10, 50, w, h);
            text.setFont(new Font(Font.SANS_SERIF, 0, textSize));
            text.setVisible(true);
            getRootPane().add(text);

            choose = new SymfoniaJButton(chooseText);
            choose.setBounds(w - 155, (h / 2) + 65, 130, 30);
            choose.addActionListener(this);
            choose.setVisible(true);
            getRootPane().add(choose);

            fileNameField = new JTextField();
            fileNameField.setBounds(25, (h / 2) + 35, w - 50, 28);
            fileNameField.addActionListener(this);
            fileNameField.setText(System.getProperty("user.dir"));
            fileNameField.setEditable(false);
            fileNameField.setVisible(true);
            getRootPane().add(fileNameField);

            info = new JXLabel();
            info.setVerticalAlignment(SwingConstants.TOP);
            text.setLineWrap(true);
            info.setBounds(10, 50, h - 100, 30);
            info.setFont(new Font(Font.SANS_SERIF, 1, textSize));
            info.setForeground(Color.RED);
            info.setVisible(true);
            getRootPane().add(text);

            save = new SymfoniaJButton(saveText);
            save.setBounds(w - 155, h - 70, 130, 30);
            save.addActionListener(this);
            save.setVisible(true);
            getRootPane().add(save);

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
     * Setzt den Titel des Fensters.
     * 
     * @param title Titel des Caption Label
     */
    public void setTitle(final String title)
    {
        this.title.setText(title);
    }

    /**
     * Setzt den Titel des Fensters.
     * 
     * @param title Titel des Caption Label
     */
    public void setText(final String text)
    {
        this.text.setText(text);
    }

    /**
     * Setzt den Dateipfad im Dateipfad-Editfeld.
     */
    protected void updateFilePath(String path, final String fileName)
    {
        final File f = new File(".");
        path = (path == null) ? f.getAbsolutePath() : path;
        fileNameField.setText(unixfyPath(path) + "/" + fileName);
    }

    /**
     * Wandelt einen Windows-Pfad in einen Unix-Pfad um.
     * 
     * @param path Pfad zum umwandeln
     * @return Umgewandelter Pfad
     */
    protected String unixfyPath(final String path)
    {
        try
        {
            final String newPath = path.replaceAll("\\\\", "/");
            return newPath;
        }
        catch (final PatternSyntaxException e)
        {
            return path;
        }
    }

    /**
     * Gibt den Auswahlbutton zurück.
     * 
     * @return Auswahlbutton
     */
    public SymfoniaJButton getChoose()
    {
        return choose;
    }

    /**
     * Gibt das Feld mit dem Pfad zur ausgewählten Datei zurück.
     * 
     * @return Dateinamensfeld
     */
    public JTextField getFileNameField()
    {
        return fileNameField;
    }

    /**
     * Gibt den Speicher-Button zurück.
     * 
     * @return Speicherbutton
     */
    public SymfoniaJButton getSave()
    {
        return save;
    }

    /**
     * Ändert den angezeigten Informationstext.
     * 
     * @param text Neuer Text
     */
    public void setInfoText(final String text, final Color color)
    {
        info.setText(text);
        info.setForeground(color);
    }

    /**
     * Callback, nachdem eine Datei ausgewählt wurde.
     * 
     * @param selected Ausgewählte Datei
     */
    public abstract void onSelectionFinished(File selected);

    /**
     * {@inheritDoc}
     * 
     * @throws WindowException
     */
    @Override
    public abstract void handleActionEvent(final ActionEvent aE) throws WindowException;

    /**
     * {@inheritDoc}
     */
    @Override
    public abstract void handleValueChanged(final ListSelectionEvent a);
}
