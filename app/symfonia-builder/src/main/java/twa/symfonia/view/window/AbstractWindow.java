package twa.symfonia.view.window;

import java.awt.event.ActionEvent;

import javax.swing.event.ListSelectionEvent;

import twa.symfonia.service.xml.XmlReaderInterface;
import twa.symfonia.view.component.SymfoniaJPanel;

/**
 * 
 * @author angermanager
 *
 */
public abstract class AbstractWindow implements WindowInterface
{

    /**
     * Frame des Fensters
     */
    protected SymfoniaJPanel root;

    /**
     * XML-Reader
     */
    protected XmlReaderInterface reader;

    /**
     * Initalisiert die Komponenten des Fensters.
     * 
     * @param w Breite
     * @param h Höhe
     * @param reader XML-Reader
     * @throws WindowException
     */
    public void initalizeComponents(final int w, final int h, final XmlReaderInterface reader) throws WindowException
    {
        this.reader = reader;
        root = new SymfoniaJPanel(null);
        root.setBounds(0, 0, w, h);
        root.setVisible(true);
    }

    /**
     * Constructor
     */
    public AbstractWindow()
    {
    }

    /**
     * Zeigt den Fensterinhalt an.
     */
    @Override
    public void show()
    {
        root.setVisible(true);
    }

    /**
     * Versteckt den Fensterinhalt.
     */
    @Override
    public void hide()
    {
        root.setVisible(false);
    }

    /**
     * Gibt das Frame des Fensters zurück.
     * 
     * @return
     */
    @Override
    public SymfoniaJPanel getRootPane()
    {
        return root;
    }

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

    /**
     * {@inheritDoc}
     */
    @Override
    public void valueChanged(final ListSelectionEvent aE)
    {
        handleValueChanged(aE);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void actionPerformed(final ActionEvent aE)
    {
        try
        {
            handleActionEvent(aE);
        }
        catch (final WindowException e)
        {
            e.printStackTrace();
        }
    }
}