# Desmos JSON

These are instructions for getting a JSON file from Desmos.

1. Save the graph on the web app and then execute in the command line:

```curl -H 'Accept: application/json' https://www.desmos.com/calculator/yrcctbabfh > /Users/sspaul2/Desktop/Math/MA425\ Development/real-analysis/metric-spaces/boundedness-in-r.json```

replacing with the desired link and target.

curl -H 'Accept: application/json' https://www.desmos.com/calculator/qfkadimcrk > /Users/sspaul2/Desktop/Math/MA425\ Development/real-analysis/metric-spaces/half-plane.json

2. Then include a fenced div thusly.

```
:::{#des-bounded-def .content-visible when-format="html"}
<script src="https://www.desmos.com/api/v1.11/calculator.js?apiKey=4f603473e10e40a1ba9b9bc2e52866d1"></script>

<div id="calculator-bounded-def" class="calculator-container" style="width: 100%; height: 600px;"></div>

<script>
  var elt = document.getElementById('calculator-bounded-def');
  var options = {
    lockViewport: true,
    expressions: false,
    keypad: false
  }
  var calculator = Desmos.GraphingCalculator(elt,options);
  

    // Load the JSON state from file and apply it
    fetch('bounded-def.json')
      .then(response => response.json())
      .then(payload => {
        if (payload && payload.product === 'graphing-3d') {
          console.error('Desmos JSON is for graphing-3d; use a 2D graphing calculator state.');
          return;
        }
        const state = payload && payload.state ? payload.state : payload;
        calculator.setState(state);
      })
      .catch(error => {
        console.error('Error loading Desmos state:', error);
      });
</script>

An illustration of Part 2 of the boundedness condition. Wherever the point $a$ is moved, there is a large enough $r$ so that the set $S$ lives inside the open ball.
:::
```

Make sure to change:
    1. The name of the fenced div (for reference), e.g. `#des-sequences`
    2. The name of the div containing the iframe window. This also goes into the script in the command `document.getElementByID()`;
    3. Change options as needed inside the script.
    4. Enter the name of the JSON file in the `fetch` command.
    5. Change the caption.

3. Below is an example with an external slider.

```
:::{#des-sup-tfae .content-visible when-format="html"}
<script src="https://www.desmos.com/api/v1.11/calculator.js?apiKey=4f603473e10e40a1ba9b9bc2e52866d1"></script>

<div id="calculator-sup-tfae" class="calculator-container" style="width: 100%; height: 300px;"></div>


  

<div class="slider-container">
  <label for="e-slider" class="left-label">$\varepsilon$</label>
  <div class="centered-slider">
  <input id="e-slider" class="desmos-slider" type="range" min="0" max="0.5" step="0.01" value="0.2" list="values">
  <datalist id="values">
    <option value="0" label="0"></option>
    <option value="0.5" label="0.5"></option>
  </datalist>
  </div>
</div>


<script>
  var eSlider = document.getElementById('e-slider');
  var e = parseFloat(eSlider.value);
  
  var elt = document.getElementById('calculator-sup-tfae');
  var options = {
    lockViewport: true,
    expressions: false,
    keypad: false
  }
  var calculator = Desmos.GraphingCalculator(elt,options);
  

    // Load the JSON state from file and apply it
    fetch('sup-tfae.json')
      .then(response => response.json())
      .then(payload => {
        if (payload && payload.product === 'graphing-3d') {
          console.error('Desmos JSON is for graphing-3d; use a 2D graphing calculator state.');
          return;
        }
        const state = payload && payload.state ? payload.state : payload;
        calculator.setState(state);
      })
      .catch(error => {
        console.error('Error loading Desmos state:', error);
      });

  eSlider.addEventListener('input', function() {
    e = parseFloat(this.value);
    calculator.setExpression({id:'epsilon-slider', latex:`\\varepsilon=${e}`});
  });
</script>

A demonstration of @thm-lub-tfae. In blue is the set $S=\left\{\frac{0}{1},\frac{1}{2},\frac{2}{3},\ldots\right\}$. When $b=1$, note that for whatever $\epsilon>0$ is chosen, there is at least one element of $S$ in both the green and orange intervals. When $b>1$, you could choose a small $\epsilon>0$ and have *no* points of $S$ in the orange and green intervals.
:::
```